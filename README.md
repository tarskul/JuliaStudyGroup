# Julia Study Group

This is a temporary project (during March 2023?) to host the files for the julia study group (in the context of the Mopo project in preparation for WP4). The project is forked from 'From Python To Julia' to get started but will be expanded dynamically as needed by the members of the study group. The Julia Study Group is a playground to experiment with the julia programming language. There will not necessarily be a big end goal or structure.

Some of the topics that will be addressed:
+ basics: dictionaries, arrays, loops, functions
+ documentation and modules
+ reading/writing files
+ using JuMP
+ using dataframes
+ two step iterative process including the JuMP model
+ calling a simple SpineOpt model from within Julia

warning: the links in this readme file are here to help you. However, there is always a risk with clicking on links. So, always check a link before you click on it.

## Join
To join the study group, send a mail to tars.verschelde@kuleuven.be . If you are part of the Mopo project, I'll add you as soon as possible. If you are not of the Mopo project, I guess you are still welcome but you will have to provide a small motivation and you'll have to accept that Mopo project members are prioritised (meaning that we might not have the time to wait for you if you lag behind too much). We'll just have to see what works and what not.

## Prerequisites
For this study group we will obviously use Julia. When I'm learning to code or when I'm trying something out, I typically find a jupyter notebook quite useful. So we'll try that as well.

### Julia

You might not have Julia already so make sure it is installed: [https://julialang.org/downloads/](https://julialang.org/downloads/)

You can check whether it is installed correctly by going to your terminal and type: `julia --version` (you might have to add julia to the environment path)

You will need some additional Julia packages: [https://docs.julialang.org/en/v1/stdlib/Pkg/](https://docs.julialang.org/en/v1/stdlib/Pkg/)

In short, in the terminal type: `julia` to open the julia environment and type `]` to get into the package manager (the text will typically become blue). To add a package type `add` with the package name, e.g. `add "IJulia"`. (Afterwards, you can then exit the package manager with backspace and exit Julia by typing: exit())

A short list of packages we will probably use:
+ IJulia (to make julia available as a kernel in the jupyter notebook)
+ Colors
+ Plots
+ JuMP (for mixed integer linear formulations such as in SpineOpt)
+ GLPK (to use the glpk solver in JuMP; you can also use other [JuMP compatible solvers](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers))
+ SpineOpt

### Python

To install and use Jupyter, you need to install Python: [https://www.python.org/downloads/](https://www.python.org/downloads/). The package manager for python is pip (there is also the option with a conda environment but I know nothing about that). Again you can check whether python is installed correclty with the command `python --version`.

### Jupyter

You can install Jupyter through pip (from python): `pip install jupyterlab`. (Be sure to install jupyterlab and not just jupyter; jupyterlab is the successor of jupyter and jupyter does not include jupyterlab by default.)

To open a jupyter notebook you can open jupyterlab with the commandline `jupyter lab` (the python scripts folder needs to be in your environment variable PATHS) or use your own preferred application. My personal favorite:
[vs code](https://code.visualstudio.com/docs/datascience/jupyter-notebooks).

(in the near future we might use jupyterlab collaboratively: [jupyter collaborative](https://jupyterlab.readthedocs.io/en/stable/user/rtc.html) or other [jupyter collaboration programs](https://datasciencenotebook.org/jupyter-realtime-collaboration))


## Additional training materials

Feel free to add training materials that you found useful.

[From Python To Julia](https://gitlab.kuleuven.be/UCM/from-python-to-julia): The original project which is dedicated to the differences between Python and Julia and remains a separate project.

[Advanced Julia training](https://gitlab.kuleuven.be/UCM/esim-advanced-julia-training): A project by the ESIM group at the KU Leuven to get students or collegues up to speed with Julia.

[JuMP](https://jump.dev/JuMP.jl/stable/): The mixed integer linear model formulation package for Julia.

[JuMP compatible solvers](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers): A list and package names of solvers that can be used in JuMP

## planning

homework:
+ install everything
+ read juliastudygroup.ipynb
+ add basic julia you thought to be nice