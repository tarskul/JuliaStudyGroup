# Julia Study Group
[![Join the chat at https://matrix.to/#/#juliastudygroup:gitter.im](https://badges.gitter.im/juliastudygroup.svg)](https://matrix.to/#/#juliastudygroup:gitter.im)

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
To join the study group, first join the gitter room (button on top of this readme file) and ask there. If you are part of the Mopo project, We'll add you as soon as possible to the Teams meeting and as a developer on github. If you are not of the Mopo project, I guess you are still welcome but you will have to provide a small motivation and you'll have to accept that Mopo project members are prioritised (meaning that we might not have the time to wait for you if you lag behind too much). We'll just have to see what works and what not.

The meetings will be held every thursday from 10:00 to 11:00 (GMT) in Teams. If you would like to join but the timing doesn't suit you, you can indicate a different timing in this form (only for Mopo project members and ignore the actual date): [Teams meeting timing](https://framadate.org/WtmVUI4eQV7zEXCJ)

## Approach
There are two parts to our learning approach. As we start at the very start we will fiddle around with some very basic code. That will be done in the jupyter notebook file and will serve later on as some sort of code library.

Then we will get more serious and we will make a more complex program. We will make a double 'optimisation' loop. The inner loop will be a mixed integer linear formulation. The outer loop will be a monte carlo analysis of the parameters of that formulation. We will also plot the results in some nice figures.

We will do that step by step. The main.jl file will hold the structure (including documentation) and the mod_name.jl file will be a file for each of us where we can try our own version of the algorithm. As we will use the same structure, we will be able to compare our files (in speed and flexibility) and learn from our differences.

## Prerequisites
For this study group we will obviously use Julia. When I'm learning to code or when I'm trying something out, I typically find a jupyter notebook quite useful. So we'll try that as well.

### Gitter
We will communicate through gitter as this is also used in WP4. Once you click on the button you are invited to the room but you actually still need an application to get it running. There will be some guidance but you might need some extra help.

Gitter has moved to [matrix](https://matrix.org/) so you need an application that runs matrix. [Element](https://element.io/) is a very solid option but there are other cute ones like [Fluffy chat](https://fluffychat.im/).

Matrix allows for different server domains. By default it selects Matrix.org but in this case we actually want gitter.im so make sure to change to that.

Finally you can make your account with a github account.

If the room is not automatically added, you can just click the gitter button above again.

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
+ SpineOpt (we'll install the developer version together in one of the meetings)

### Python

To install and use Jupyter, you need to install Python: [https://www.python.org/downloads/](https://www.python.org/downloads/). The package manager for python is pip (there is also the option with a conda environment but I know nothing about that). Again you can check whether python is installed correclty with the command `python --version`.

### Jupyter

You can install Jupyter through pip (from python): `pip install jupyterlab`. (Be sure to install jupyterlab and not just jupyter; jupyterlab is the successor of jupyter and jupyter does not include jupyterlab by default.)

To open a jupyter notebook you can open jupyterlab with the commandline `jupyter lab` (the python scripts folder needs to be in your environment variable PATHS) or use your own preferred application. My personal favorite:
[vs code](https://code.visualstudio.com/docs/datascience/jupyter-notebooks).

We would like to use [jupyter collaboratively](https://jupyterlab.readthedocs.io/en/stable/user/rtc.html) but that requires a server. I've contacted my institution for this but at the moment it does not seem to get much traction. Any other suggestions are welcome.
Alternatively, there are also other [jupyter collaboration programs](https://datasciencenotebook.org/jupyter-realtime-collaboration).


## Additional training materials

Feel free to add training materials that you found useful.

[From Python To Julia](https://gitlab.kuleuven.be/UCM/from-python-to-julia): The original project which is dedicated to the differences between Python and Julia and remains a separate project.

[Advanced Julia training](https://gitlab.kuleuven.be/UCM/esim-advanced-julia-training): A project by the ESIM group at the KU Leuven to get students or collegues up to speed with Julia. The owner of the repository told me that if there were any issues or suggestions, you can contact them through the foreseen issue list. They'll try to respond as soon as possible.

[JuMP](https://jump.dev/JuMP.jl/stable/): The mixed integer linear model formulation package for Julia.

[JuMP compatible solvers](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers): A list and package names of solvers that can be used in JuMP

[Git explained by Ole](https://ole.mn/estp2022/slides/practical_git/)

## Planning

2nd of March 2023

homework:
+ install everything as indicated above
+ read juliastudygroup.ipynb
+ add basic julia you thought to be nice

agenda:
+ if there are newcomers: brief overview of last meeting (by means of this readme)
+ brief discussion on any issues during installation
+ playing around with the jupyter notebook to exchange our understanding of the basics of Julia