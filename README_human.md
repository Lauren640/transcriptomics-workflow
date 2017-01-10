# Transcriptomics Workflow

Instructions to take raw transcriptomics reads and progress to a counts file that can be used in `R` packages for statistical analysis of differential expression.

To follow this tutorial you will need to have some basic familiarity with working in a unix-like environment.  An excellent place to start would be to attend a [software carpentry](http://software-carpentry.org/) or [data carpentry](http://www.datacarpentry.org/) workshop, or complete the [Unix bootcamp](
http://rik.smith-unna.com/command_line_bootcamp/?id=9xnbkx6eaof).  The VLSCI also have several tutorials for [working with unix and/or a HPC environment](http://vlsci.github.io/lscc_docs/tutorials/)

## Connect to Analysis Server
This will usually mean opening a terminal and using `ssh` to connect. The general format of this command is;

```bash
	ssh username@my.hpc.server.edu.au
```
## Adding Files into a HPC Terminal
To begin, navigate to the directory containing the files you want to upload to the server. A new terminal should appear on the screen.
The next step is to transfer the files from the new terminal into the HPC terminal. This step is completed using the 'secure copy' or `scp` command and is as follows:

```bash
	scp -r /path/to/the/data/ username@my.hpc.server.edu.au:~/
```

If you are unsure of the path to the data, use the `pwd` command in the terminal, as this will display the path to your current file/directory.
*Note the space either side of the `-r` and before the username*


*After downloading, it is a good idea to keep the original, unmodified files somewhere safe.*

#### Combining Data from Different Files
*Depending on the location of your files, you may not need to complete this step*
It may be the case that your data files are located in separate files within one directory \(my_directory\). Start by finding all of the required files by using the `find` command. This will ensure that you have all the correct files when you attempt to link them. The command is as follows:

```bash
	find path/to/files/ -name '*common.file.name'
```

The above command tells the cluster to find, within a particular directory, all the files that contain that particular name. You may wish to change the search to find all files that end with a particular file extension. If this is the case you would change '\*common.file.name' with '\*.file.extension'.

The output for this command will show a list of the files that contain the common name that you specified above.

### Creating a Loop to Link Files
A loop is a tool that enables you to execute a set of commands repeatedly.
This step uses the loop to take the original files and create a link with them into another directory. This allows one version of the files to be modified, while the originals remain untouched. The command for this is as follows:

```bash
	for f in `find path/to/files -name '*common.file.name'`; do ln -s $f .; done
```

This command says that for all the files listed in the step above, link them to the current directory.  
This creates a link between one directory \(i.e. the directory that contains the original files\) and your current directory \(indicated by the period.\) which allows you to access all the files in the original directory in your current directory, without changing anything about the original files.

This process is much more efficient than using the `cp` command to copy all the files into a new directory.

## Downloading the Human Genome
This step will be important when using the HISAT program to align the RNAseq reads onto the genome. This step will use the `wget` command, which allows the user to download particular files from the web. The general format of this command is:

```bash
	wget http://website.com/files
```
To download a version of the *human genome* with HiSat2 indexes, enter the following command into the terminal on HPC

```bash
	wget ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/data/grch38.tar.gz
```

You also need to download a gene annotation file for transcript assembly. Using the same command above, download the following: ftp://ftp.ensembl.org/pub/release-87/gtf/homo_sapiens/Homo_sapiens.GRCh38.87.gtf.gz

### Unpacking the Genome File
The human genome file and the annotation file given above are both compressed files and therefore need to be unpacked.  *This step will be different if you have downloaded a different version of the human genome*.
To unpack the version of the human genome given above, enter the command as follows:

```bash
	tar -zxvf grch38.tar.gz
```
To unpack the annotated file enter the command as follows:

```bash
	gunzip Homo_sapiens.GRCh38.87.gtf.gz
```

### Building the Genome Index for HISAT2
Before continuing, the genome file downloaded above has to be built into an index which can be utilized by the HISAT2 program. In the folder \'grch38\', there is a file \'make_grch38.sh\', which is a built-in shell script that is used to build the genome index. Ensuring you're in the \'grch38\' directory, enter the command as follows:

```bash
 	./make_grch38
```

## Load the HISAT2 Program
This is done using the module command which can be used to load programs for use on the cluster. To load the HISAT2 program use the following command:

```bash
	module load hisat2
```

You may check that the program has been installed by entering:

```bash
	which hisat2
```

This should return a path showing the location to the hisat2 program.

Using this same process load the `samtools` program.

## Creating and Running the HISAT2 Script
When working with a large amount of files, it is not wise to submit them to the cluster in just one large job, as jobs with large resource requirements may take a long time to run.  A better way to make optimal use of cluster resources is to submit many smaller jobs. This requires that many separate job scripts are created. To do this we use a loop over all input files, modifying a template job script each time to insert the filename.

An example template HISAT2 script can be seen in the file labelled `01_HISAT.sh`.

Generally, any of the lines beginning with a `#` are comments and therefore ignored. However, when writing PBS scripts, there are exceptions. The script begins with `#!/bin/bash` or a \'shebang\', which simply indicates that the script is a bash script. The following lines that begin with `#PBS` are PBS directives and give the script information about how the job should be run. The script itself begins on line 18. This line tells the job to make `DUMMY` the variable for all files, as it may then be substituted for the name of a file, specified in the command line. The next command, on line 21, tells the job to navigate into a specific directory. By using an absolute directory, this step ensures that the relative pathways featured in the next command are correct and that the output files will be placed into the correct directory.

#### HISAT2 Command - Explained
Line 26 begins the actual hisat2 command and was modeled from the usage method \(which can be accessed by entering `hisat2` on the command line\). Firstly, it is important to specify the path to the hisat2 module as the script will not recognize if it has been previously loaded on the cluster. This path can be found by entering the command `which hisat2`. The `-p` command is an option which tells the hisat2 program how many CPUs it may use. The `-x` specifies the index and is followed by a path to the genome index, relative to the path specified on line 21. The `-U` may be substituted with a `-1` or a `-2` and specifies the type of file to be aligned; either unpaired `-U` or with paired ends `-1` and `-2`. The final section of this command line outputs the files to the samtools program as .sam files.

#### Samtools Command - Explained
The final line is a command which takes the sam output files from the previous command, sorts them and converts them to .bam files. The command begins by providing the path to the samtools program. The `sort` command tells samtools to sort the aligned data, produced by the hisat2 program. The other commands are a part of the samtools options, but are explained as follows: `-@` tells the program how many threads it may use when running; the `o` command tells samtools where to output the files \(as .bam files\).

### Running the Command Loop
For the above script to run through all the files efficiently, it needs to be put into a loop in the command line. To begin, the script needs to be downloaded to the cluster using the `scp` command \(In the \'Adding Files into a HPC Terminal\' above\). The command below was used to run the script 01_HISAT.sh and produces separate jobs for each file.

``` bash
	for f in *fastq.gz; do sed s/DUMMY/$f/ 01_HISAT.sh | qsub -; done
```

#### The Command Loop - Explained
The important commands in the above loop are `for f in _`, `do`, and `done`. A simplified way of stating this command is: *for* all of the files specified, *do* a particular command and, *done* - ends the loop. The particular command above states that for all the files ending in `fastq.gz`, do the `sed` command on the 01_HISAT.sh file and pipe the output to qsub. `sed` is a text editor that edits text in a non-interactive way, without altering the original text. The most common `sed` command is the substitution command or `s`. An example of this command is as follows: `sed s/old/new/ s_script.sh`, which searches the script called s_script.sh and replaces the text \'old\' with the text \'new\'. In the loop above, the sed command searches the 01_HISAT.sh text and substitutes the word \'DUMMY\' for the name of a file. The command line then pipes this command to qsub to submit the job to the cluster. The pipe command is very useful as it passes the output from one command (i.e. the sed command) to another (i.e. qsub). The loop ends with the command `done`, which indicates that the loop is finished. The loop then repeats, substituting a different file for DUMMY each time, until all the files have been submitted as jobs.
*The status of these jobs can be viewed by entering `qstat -u username` into the command line*.

After running this command, there should be 3 types of new files in your directory; .bam files, .sam files and hisat.o\* files. The hisat.o\* output files will show you the output from each alignment with each file and should give an overall alignment rate. The next step is to take the .bam files and run them through the stringtie program for transcript assembly.

*This step took approximately 10 minutes for each data file*

## Creating and Running the StringTie Command
Writing and running the stringtie script is very similar to the hisat script above. The stringtie program will assemble the transcripts to the annotated genome.

An example of a stringtie script can be seen in the file labelled 02.STRINGTIE.sh.

All of the #PBS directive should remain the same, the `f=DUMMY` should remain the same; and the path to the current directory should remain the same. The only thing that will change is the command line. To begin, the command gives the path to the stringtie program, and $f will be a variable for the files. The next command, `-G` is an option that allows you to specify the path to the annotated reference gene \(which we downloaded earlier\). The `-o` command allows you to specify an output file name for the assembled transcripts. In the example script, the output file provided is `${f%.bam}stringtie.gtf`, which tells the program to cut the \'.bam\' from the file and add \'stringtie.gtf\'. The command then lists the number of CPUs required for the command using `-p 4`. The next command `-v` tells the program to output all of the processing details into the output folder that it will produce, but is not necessary when running this script. Finally the `-l` command names a prefix for the output transcriptions. In the example given, we simply cut the \'\_R1.bam\' from the data file name. This step will be important when merging the transcripts in the next section. The script must then be loaded to the cluster using the `scp` command. The script may then be submitted to the job manager using the command below \(which is very similar to the hisat2 command loop\):

```bash
	for f in *.bam; do sed s/DUMMY/$f/ 02_STRINGTIE.sh | qsub -; done
```

*The status of these jobs can be viewed by entering `qstat -u username` into the command line*

This command should then output two types of files into the directory: stringtie.o\* files and \*stringtie.gtf files.

*This step took approximately 10 minutes for each data file*

### Merging the StringTie Results
This step allows you to merge all of the transcripts from all of the data files to an annotated reference gene \(if included\). Before entering this command, you must first create a .txt file that has all the names of the .gtf files, created in the previous step, with each file name on a **single line**. Download this file to your HPC directory using the `scp` command. **Make sure to run StringTie in the same directory as all the .gtf files.** Otherwise you will need to include the full path to the files in front of each gtf file name in the .txt file. The command is as follows:

```bash
	stringtie --merge -G ../Homo_sapiens.GRCh38.87.gtf -o stringtie_merged.gtf mergelist.txt
```

This command tells stringtie to merge the .gtf files to the annotated reference genome \(`-G`\) and output a merged file called \'stringtie_meregd.gtf\'.

*This step took approximately 30 minutes for 400 data files*

## Creating and Running the Stringtie Script for Ballgown
This script is very similar to the stringtie script and will estimate the transcript abundance and output the data into ballgown tables \(required for the next step\). Details of the options for this script can be seen by loading stringtie and entering `stringtie` into the command line.

An example of a script can be seen in the file 03_BALLGOWN.sh.

The first section of the script provides the location of the stringtie program, as above. The `-e` command tells the program to only estimate the abundance of given reference transcripts and the `-B` command tells stringtie to enable output of ballgown table files which will be created in the same directory as the output GTF. The `-p` and `-G` are the same in the stringtie script above. The final command `-o` tells the program to output the data into a \".gtf\" file instead of \"\_R1.bam\", within a subdirectory labelled after the data file name (i.e.\"${f%\_R1.bam}\"), within a directory called \"ballgown\". \(*in this step, the command is telling the program to create a subdirectory and a directory to deposit all the files. However, if you have already created a directory, you will instead need to provide a relative path to its location*\). After creating the script, it must be loaded to the cluster using the `scp` command and placed into the correct directory. Once the script is loaded, enter the following command to run the script:

```bash
	for f in *.bam; do sed s/DUMMY/$f/ 03_BALLGOWN.sh | qsub -; done
```

The output of this command may then be found in the directory labelled \"ballgown\". The output produced in each subdirectory should consist of one \'.gtf\' file and multiple \'.ctab\' files. The \'.gtf\' file contains all the information outputted by stringtie (i.e. the gene ID, the transcript ID, the reference gene name, the coverage, the TPM, etc.). The \'.ctab\' files contain only some of the information from the \'.gtf\' file. To view a small section of each of these outputs, use the `head *` command, which allows you to view just the top few lines of all the files.

*This step took approximately 7 minutes for each data file*

## Learning R
The next step of this workflow requires some knowledge regarding the statistical language \'R\'.
To begin, you may need to download [R](https://www.r-project.org/) and [RStudio](https://www.rstudio.com/) to your computer. It would be a good idea to work through this tutorial by Code School called [Try R](http://tryr.codeschool.com/levels/1/challenges/1) or try [Swirl](http://swirlstats.com/) - an interactive tutorial that teaches straight from the command line.
After this initial introduction to R, it may be useful to read through the book [R for Data Science](http://r4ds.had.co.nz/index.html) by Hadley Wickham, which will introduce you the applications of R for data science.

## Transferring your data to the Desktop
To be able to access the data in RStudio and run ballgown, the data needs to be transferred from the cluster to the desktop. There are multiple ways to do this, depending on what data you wish to move.

### rsync command
`rsync` works similarly to `rcp` to remotely copy files from one location to another, but does it much faster. An interesting option of this command is that it allows you to exclude data based on a particular pattern. For instance, in the example below, the \'.gtf\' files were excluded as they contained more information than necessary and were too large to transfer onto the desktop. View the options for this command by enterring `man rsync` into the terminal. The following is an example of the `rsync` command and was executed on the computers terminal, NOT the HPC.

``` bash
	rsync -avur --exclude=*.gtf username@hpc.edu.au:~/path/to/files/ .
```

### scp command
It is possible to still use the `scp` command used previously - depending on your data. This will not work if you wish to exclude data from your files.

```bash
	scp -r username@hpc.edu.au/path/to/files/ .
```
