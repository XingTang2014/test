#!/bin/bash
# stjude_chipseq_report 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

set -e -x -o pipefail

main() {

    echo "Value of parameter_file: '$parameter_file'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$parameter_file" -o parameter_file
    
    source parameter_file
    report_section=1
    cat -A parameter_file

    # date and title
    date > $out_prefix.readme.doc
    echo "St Jude ChIP-seq analysis pipeline report" >> $out_prefix.readme.doc
    echo "Your ChIP experiment is $ChIP_fastq_name while control experiment is $Control_fastq_name" >> $out_prefix.readme.doc
    echo "Reference genome is $genome" >> $out_prefix.readme.doc
    echo >> $out_prefix.readme.doc

    # FASTQC section
    echo "$report_section. Please check the sequencing quality reports from FASTQC" >> $out_prefix.readme.doc
    echo "   Open \"FASTQC/$ChIP_fastq_name.stats-fastqc.html\" and \"FASTQC/$Control_fastq_name.stats-fastqc.html\" " >> $out_prefix.readme.doc
    echo >> $out_prefix.readme.doc
    ((report_section++))

    for i in `dx ls $DX_PROJECT_CONTEXT_ID:$out_folder/Results/$out_prefix/`
    do
	if [ "$i" == "MACS2/" ] || [ "$i" == "SICER/" ]; then 
	    peak_caller=${i:0:5}
	    if [ "$peak_caller" == "MACS2" ]; then raw_peak="${ChIP_fastq_name}_peaks.xls"; peak_type="narrow" ; fi
	    if [ "$peak_caller" == "SICER" ]; then 
		if [ "`dx ls $DX_PROJECT_CONTEXT_ID:$out_folder/Results/$out_prefix/SICER/ | grep islands-summary`" == "" ]; then 
			raw_peak="$(dx ls $DX_PROJECT_CONTEXT_ID:$out_folder/Results/$out_prefix/SICER/ | grep scoreisland )"
		else
			raw_peak="$(dx ls $DX_PROJECT_CONTEXT_ID:$out_folder/Results/$out_prefix/SICER/ | grep islands-summary )"
		fi 
		peak_type="broad" 
	    fi

	    # mapping and peak calling metrics
	    echo "$report_section. You performed $peak_type peak calling" >> $out_prefix.readme.doc
	    echo "   Open \"$peak_caller/$ChIP_fastq_name.metrics.txt\" to check the mapping and peak calling metrics" >> $out_prefix.readme.doc
	    echo >> $out_prefix.readme.doc
	    ((report_section++))

	    # cross correlation
	    echo "$report_section. Open \"$peak_caller/${ChIP_fastq_name}_phantomPeak.pdf\" and \"$peak_caller/${Control_fastq_name}_phantomPeak.pdf\" to check the cross correlation plots." >> $out_prefix.readme.doc
	    echo >> $out_prefix.readme.doc
	    ((report_section++))

	    # peak files with coordinates
	    peak_bed=$(dx ls $DX_PROJECT_CONTEXT_ID:$out_folder/Results/$out_prefix/$peak_caller/*.bed)
	    peak_bb=$(dx ls $DX_PROJECT_CONTEXT_ID:$out_folder/Results/$out_prefix/$peak_caller/*.bb)
	    if [[ "$peak_bed" =~ .*\.clean\.bed$ ]]; then
		echo "$report_section.$sub_section Coordinates for blacklist filtered peak regions are in \"$peak_caller/$peak_bed\". \"$peak_caller/$raw_peak\" has all the un-filtered peaks with detailed information (pvalue, FDR and etc.)." >> $out_prefix.readme.doc
	    else 
		echo "$report_section.$sub_section Coordinates for predicted peaks are in \"$peak_caller/$peak_bed\". You can also open \"$peak_caller/$raw_peak\" to check more information about peaks (pvalue, FDR and etc.)." >> $out_prefix.readme.doc
	    fi
	    echo >> $out_prefix.readme.doc
	    ((report_section++))
	fi
    done

    # visulization
    echo "$report_section. Upload \"$peak_caller/$peak_bed\" or \"$peak_caller/$peak_bb\", \"$peak_caller/${ChIP_fastq_name}.bw\" and \"$peak_caller/${Control_fastq_name}.bw\" to IGV (http://software.broadinstitute.org/software/igv/) or UCSC genome browser (https://genome.ucsc.edu/cgi-bin/hgGateway) to view." >> $out_prefix.readme.doc

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    out_report=$(dx upload --path $DX_PROJECT_CONTEXT_ID:$out_folder/Results/${out_prefix}/ $out_prefix.readme.doc --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output out_report "$out_report" --class=file
    dx rm $DX_PROJECT_CONTEXT_ID:$out_folder/Results/${out_prefix}/$out_prefix.parameters.txt
}