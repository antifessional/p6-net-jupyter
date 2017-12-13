## Synopsis

A dockerized jupyter notebook installation with python3 and Perl6

## Installation 

run with 

    docker run -d --name jupyter-base \
        -p 8888:8888 \
        -v $CONFIG:/home/jovyan/.jupyter \
        -v $NOTEBOOKS:/home/jovyan/work \
        gabrielash/base-notebook

  1.    the CONFIG Directory (Full Path) allows overriding jupyter settings. For example 
        by substituting a fixed authentification token. There is a demo
        jupyter_notebook_config.py that you can vopy into it and edit.
  2.    the NOTEBOOKS Directory will hold all notebooks created. It is the top directory
        for the Jupyter server


