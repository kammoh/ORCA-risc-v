#!/usr/bin/python
import sys
import shlex
import shutil
import os
import subprocess
import re
import time
import threading
###########################################################################
def pushd(dirname):
    class PushdContext:
        def __init__(self, dirname):
            self.cwd = os.path.realpath(dirname)
        def __enter__(self):
            self.original_dir = os.getcwd()
            os.chdir(self.cwd)
            return self
        def __exit__(self, type, value, tb):
            os.chdir(self.original_dir)

    return PushdContext(dirname)

class system:
    files_needed=("Makefile",
                  "riscv_hw.tcl",
                  "riscv_test.vhd",
                  "sevseg_conv.vhd",
                  "vblox1.qpf",
                  "vblox1.qsf",
                  "vblox1.qsys",
                  "vblox1.sdc")

    def __init__(self,
                 branch_prediction,
                 btb_size,
                 divide_enable,
                 include_counters,
                 multiply_enable,
                 pipeline_stages,
                 shifter_single_cycle,
                 fwd_alu_only):
        self.branch_prediction=branch_prediction
        self.btb_size=btb_size
        self.divide_enable=divide_enable
        self.include_counters=include_counters
        self.multiply_enable=multiply_enable
        self.pipeline_stages=pipeline_stages
        self.shifter_single_cycle=shifter_single_cycle
        self.fwd_alu_only=fwd_alu_only
        self.directory=("./veek_project_"+
                        "bp%s_"+
                        "btbsz%s_"+
                        "div%s_"+
                        "mul%s_"+
                        "count%s_"+
                        "pipe%s_"+
                        "ssc%s_"+
                        "fwd%s") %(self.branch_prediction,
                                   self.btb_size,
                                   self.divide_enable,
                                   self.multiply_enable,
                                   self.include_counters,
                                   self.pipeline_stages,
                                   self.shifter_single_cycle,
                                   self.fwd_alu_only)
    def create_build_dir(self ):
        print "creating %s"%self.directory
        try:
            os.mkdir(self.directory)
        except:
            pass
        for f in system.files_needed :
            shutil.copy2("veek_project/"+f,self.directory)
        with open(self.directory+"/config.mk","w") as f:
            f.write('BRANCH_PREDICTION="%s"\n'   %self.branch_prediction)
            f.write('BTB_SIZE="%s"\n'            %self.btb_size)
            f.write('MULTIPLY_ENABLE="%s"\n'     %self.include_counters)
            f.write('DIVIDE_ENABLE="%s"\n'       %self.divide_enable)
            f.write('INCLUDE_COUNTERS="%s"\n'    %self.multiply_enable)
            f.write('PIPELINE_STAGES="%s"\n'     %self.pipeline_stages)
            f.write('SHIFTER_SINGLE_CYCLE="%s"\n'%self.shifter_single_cycle)
            f.write('FORWARD_ALU_ONLY="%s"\n'    %self.fwd_alu_only)
    def build(self,use_qsub=False,build_target="all"):
        make_cmd='make -C %s %s'%(self.directory,build_target)
        if use_qsub:
            qsub_cmd='qsub -q main.q -b y -sync y -j y  -V -cwd -N "veek_project" ' + make_cmd
            proc=subprocess.Popen(shlex.split(qsub_cmd))
        else:
           proc=subprocess.Popen(shlex.split(make_cmd))
           proc.wait()
        return proc

    def get_build_stats(self):
        timing_rpt=self.directory+"/output_files/vblox1.sta.rpt"
        synth_rpt = self.directory+"/output_files/vblox1.map.rpt"
        fit_rpt=self.directory+"/output_files/vblox1.fit.rpt"
        with open(timing_rpt) as f:
            rpt_string = f.read()
            fmax=re.findall(r";\s([.0-9]+)\s+MHz\s+;\s+clock_50",rpt_string)
            fmax=min(map(lambda x:float(x) , fmax))
            print "fmax=%f"%fmax
            self.fmax=fmax
        with open(synth_rpt) as f:
            rpt_string = f.read()
            self.cpu_prefit_size=int(re.findall(r"^;\s+\|riscV:riscv_0\|\s+; (\d+)",rpt_string,re.MULTILINE)[0])
            print "cpu_prefit_size=%d" %self.cpu_prefit_size
        with open(fit_rpt) as f:
            rpt_string = f.read()
            self.cpu_postfit_size=int(re.findall(r"^;\s+\|riscV:riscv_0\|\s+; (\d+)",rpt_string,re.MULTILINE)[0])
            print "cpu_postfit_size=%d" %self.cpu_postfit_size
        with open(self.directory+"/summary.txt","w") as f:
            f.write('BRANCH_PREDICTION="%s"\n'   %self.branch_prediction)
            f.write('BTB_SIZE="%s"\n'            %self.btb_size)
            f.write('DIVIDE_ENABLE="%s"\n'       %self.divide_enable)
            f.write('INCLUDE_COUNTERS="%s"\n'    %self.multiply_enable)
            f.write('MULTIPLY_ENABLE="%s"\n'     %self.include_counters)
            f.write('SHIFTER_SINGLE_CYCLE="%s"\n'%self.shifter_single_cycle)
            f.write("FORWARD_ALU_ONLY=%s\n"      %self.fwd_alu_only)
            f.write( "fmax=%f\n"                 %self.fmax)
            f.write( "cpu_prefit_size=%d\n"      %self.cpu_prefit_size)
            f.write( "cpu_postfit_size=%d\n"     %self.cpu_postfit_size)



def summarize_stats(systems):
    try:
        os.mkdir("summary")
    except:
        pass
    with open("summary/summary.html","w") as html:
        html.write("\n".join(("<!DOCTYPE html>",
                              "<html>",
                             "<head>",
                              ' <meta charset="UTF-8"> ',
                             '<script src="http://www.kryogenix.org/code/browser/sorttable/sorttable.js"></script>',
                              "<style>",
                              "table, th, td {",
                              "    border: 1px solid black;",
                              "    border-collapse: collapse;",
                              "}",
                              "</style>",
                              "</head>",
                             "<body>",
                             "<table class=sortable >")))
        html.write("<thead><tr><td></td>")
        for th in ('branch prediction','btb size','multiply','divide',
                   'perfomance counters','pipeline stages','single cycle shift',
                   'fwd alu only','prefit size','postfit size','FMAX'):
            html.write('<th class="rotate"><div><span>%s</span></div></th>'%th)
        html.write("</thead></tr>\n")


        for sys in systems:
            html.write("<tr>")
            html.write("<td>%s</td>"%str(sys.directory))
            html.write("<td>%s</td>"%str(sys.branch_prediction))
            html.write("<td>%s</td>"%str(sys.btb_size))
            html.write("<td>%s</td>"%str(sys.multiply_enable))
            html.write("<td>%s</td>"%str(sys.divide_enable))
            html.write("<td>%s</td>"%str(sys.include_counters))
            html.write("<td>%s</td>"%str(sys.pipeline_stages))
            html.write("<td>%s</td>"%str(sys.shifter_single_cycle))
            html.write("<td>%s</td>"%str(sys.fwd_alu_only))
            html.write("<td>%s</td>"%str(sys.cpu_prefit_size))
            html.write("<td>%s</td>"%str(sys.cpu_postfit_size))
            html.write("<td>%s</td>"%str(sys.fmax))
            html.write("</tr>\n")
        html.write("</table></body></html>")



SYSTEMS=[ system(branch_prediction="false",
                 btb_size="1",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="3",
                 fwd_alu_only="1"),
          system(branch_prediction="false",
                 btb_size="1",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="4",
                 fwd_alu_only="1"),
          system(branch_prediction="true",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="3",
                 fwd_alu_only="1"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="1",
                 shifter_single_cycle="0",
                 pipeline_stages="3",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="1",
                 pipeline_stages="3",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="1",
                 include_counters="0",
                 shifter_single_cycle="1",
                 pipeline_stages="3",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="1",
                 multiply_enable="1",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="3",
                 fwd_alu_only="0"),
          system(branch_prediction="true",
                 btb_size="4096",
                 divide_enable="1",
                 multiply_enable="1",
                 include_counters="1",
                 shifter_single_cycle="0",
                 pipeline_stages="3",
                 fwd_alu_only="0"),
          #4 stage pipeline systems
          system(branch_prediction="false",
                 btb_size="1",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
          system(branch_prediction="true",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="1",
                 shifter_single_cycle="0",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="0",
                 include_counters="0",
                 shifter_single_cycle="1",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="0",
                 multiply_enable="1",
                 include_counters="0",
                 shifter_single_cycle="1",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
          system(branch_prediction="false",
                 btb_size="256",
                 divide_enable="1",
                 multiply_enable="1",
                 include_counters="0",
                 shifter_single_cycle="0",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
          system(branch_prediction="true",
                 btb_size="4096",
                 divide_enable="1",
                 multiply_enable="1",
                 include_counters="1",
                 shifter_single_cycle="0",
                 pipeline_stages="4",
                 fwd_alu_only="0"),
      ]


if __name__ == '__main__':

    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--stats-only',dest='stats_only',action='store_true',default=False)
    parser.add_argument('--no-stats',dest='no_stats',action='store_true',default=False)
    parser.add_argument('--build-target',dest='build_target',default='all')
    parser.add_argument('--use-qsub',dest='use_qsub',action='store_true',default=False)
    args=parser.parse_args()

    for s in SYSTEMS:
        s.create_build_dir()
    processes=[]
    for s in SYSTEMS:
        if not args.stats_only:
            processes.append(
                s.build(args.use_qsub,args.build_target))

    for p in processes:
        p.wait()

    for s in SYSTEMS:
        if not args.no_stats:
            s.get_build_stats()

    if not args.no_stats:
        summarize_stats(SYSTEMS)
