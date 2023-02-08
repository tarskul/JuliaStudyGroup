# From Python To Julia

warning: the links here are to help you. However, there is always a risk with clicking on links. So, always check a link before you click on it.

Remark from the original author (Tars Verschelde): I made this Jupyter notebook quickly for myself so it might not be the best learning material you can find but I made it available because it still might be helpful for you too.

For a more advanced Julia training, I refer to [https://gitlab.kuleuven.be/UCM/esim-advanced-julia-training](https://gitlab.kuleuven.be/UCM/esim-advanced-julia-training)

## prerequisites

### python

I assume that you already have python otherwise this repository is probably not what you are looking for.

### Jupyter

The main differences from python to julia are written in the interactive Jupyter Notebook. Check out the project website for more information on Jupyter Notebooks ([https://jupyter.org/](https://jupyter.org/)). To get started first download jupyterlab with the following command (assuming you already have python installed): pip install jupyterlab

To open a jupyter notebook you can open jupyterlab with the commandline or use your own preferred application. My personal favorite:
[https://code.visualstudio.com/docs/datascience/jupyter-notebooks](https://code.visualstudio.com/docs/datascience/jupyter-notebooks)

### Julia

You might not have Julia already so make sure it is installed: [https://julialang.org/downloads/](https://julialang.org/downloads/)

You can check whether it is installed correctly by going to your terminal and type: julia --version

To be able to use Julia with jupyter notebooks you'll also need to install IJulia with the package manager. Open a Julia in the terminal and type two lines: ]

To get in the package manager and then to actually download the package:

add "IJulia"

You can then exit the package manager with backspace and exit Julia by typing: exit()

Now you should be able to open JupyterLab (or vscode) and choose a Julia kernel.


## Contributions

Feel free to pass this repository around or to make changes. When making changes I only ask that the document stays compact or at least very structured. I am aiming for quick and easy.

If you don't have access, you can mail me the changes or request access if you are planning to make multiple changes. You can mail me for as long as I'll work at KU Leuven: tars.verschelde@kuleuven.be
