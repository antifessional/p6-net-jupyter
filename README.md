# Net::Jupyter

## SYNOPSIS

Net::Jupyter is a Perl6 Jupyter kernel

## Introduction

  This is a perl6 kernel for jupyter 

  as of version 0.0.1, it only implements the absolute minumum messages

  kernel_info and execute_request

  it is also INSECURE and can allow an authorized user to run arbitrary code on your computer
  
#### Status

  In EARLY development.

  Current version runs every cell is its won conext. 

#### Alternatives

  There is an existing perl6 kernel. I built this one because I couldn't get it running

#### Versions

#### Portability

## Example Code

## Documentation

  see http://jupyter.org/ 

## Installation

  The module files are installed normally, but the kernel must be installed  separately. 

  There is an installation script in the bin directory. It can also be run with 'make install.'

  Assuming jupyter is already installed on your system, and  LOCAL_HOME is defined, 

  it will try to install in the correct .local subdir that Anaconda recognizes 
  
  for jupyter kernels.  You can also specify a custom dirctory as an argument

  or you can read the script and install manually.




