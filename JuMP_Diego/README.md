# Generation Expansion Planning
Generation expansion planning problem in Julia considering network constraints

# Files description
+ **gep-main.jl**: Main file including reading the data, creating the optimization model, and solving it

+ **functions.jl**: Auxiliry file with the functions to process the input data

+ **Parameters.toml**: Configuration file with the input data files location and names, and output file folder

+ **inputs**: Folder with the input data in CSV files for one representative period

+ **outputs**: Folder with the output results in CSV files

# Mathematical formulation

## Indices
| **Name** | **Description**    |
|----------|--------------------|
| $t$      | time steps         |
| $g$      | generation units   |
| $n$      | nodes              |
| $l$      | transmission lines |

## Parameters
| **Name** | **Domains** | **Description**                                             |
|----------|-------------|-------------------------------------------------------------|
| pVOLL    |             | Value of Lost Load [\$/MWh]                                 |
| pWeight  |             | Representative period weight [hours]                        |
| pInvCost | $g$         | Investment cost [\$/MW]                                     |
| pVarCost | $g$         | Variable production cost [\$/MWh]                           |
| pUnitCap | $g$         | Capacity per each invested unit [MW/unit]                   |
| pGenCon  | $g$         | Generation connection node [node]                           |
| pGenAva  | $n,g,t$     | Generation availability (e.g., load factor) [p.u.]          |
| pDemand  | $n,  t$     | Demand per node [MW]                                        |
| pNodeA   | $l$         | Node A of transmission line l [node]                        |
| pNodeB   | $l$         | Node B of transmission line l [node]                        |
| pExpCap  | $l$         | Maximum transmission export capacity (A->B) [MW]            |
| pImpCap  | $l$         | Maximum transmission import capacity (A<-B) [MW]            |

## Variables
| **Name**  | **Domains** | **Description**              |
|-----------|-------------|------------------------------|
| vTotCost  |             | Total system cost [\$]       |
| vInvCost  |             | Total investment cost [\$]   |
| vOpeCost  |             | Total operating cost [\$]    |
| vGenInv   | $g$         | Generation investment [1..N] |
| vGenProd  | $g,t$       | Generation production [MW]   |
| vLineFlow | $l,t$       | Transmission line flow [MW]  |
| vLossLoad | $n,t$       | Loss of load [MW]            |

## Equations
| **Name**                                    | **Domains** | **Description**                    |
|---------------------------------------------|-------------|------------------------------------|
| [eObjFun](#eobjfun)                         |             | Total system cost      [\$]        |
| [eInvCost](#einvcost)                       |             | Total investment cost      [\$]    |
| [eOpeCost](#eopecost)                       |             | Total operating cost      [\$]     |
| [eNodeBal](#enodebal)                       | $n,t$       | Power system node balance   [MWh]  |
| [eMaxProd](#emaxprod)                       | $n,g,t$     | Maximum generation production [MW] |
| [eMaxLineExpImp](#emaxlineexp--emaxlineimp) | $l,t$       | maximum line export capacity [MW]  |
| [eMaxLineExpImp](#emaxlineexp--emaxlineimp) | $l,t$       | maximum line import capacity [MW]  |

### *eObjFun*
$$
\displaystyle{\min vTotCost = vInvCost + vOpeCost}
$$

### *eInvCost*
$$
vInvCost = \displaystyle \sum_{g}(pInvCost_{g} \cdot pUnitCap_{g} \cdot vGenInv_{g})
$$

### *eOpeCost*
$$
vOpeCost = pWeight \cdot (\displaystyle \sum_{g,t} (pVarCost_{g} \cdot vGenProd_{g,t} ) + \sum_{n,t} (pVOLL \cdot vLossLoad_{n,t} ))
$$

### *eNodeBal*
$$
 \displaystyle \sum_{g|pGenCon_{g}=n}vGenProd_{g,t} +\displaystyle \sum_{l|pNodeB_{l}=n}vLineFlow_{l,t} -\displaystyle \sum_{l|pNodeA_{l}=n}vLineFlow_{l,t} + vLossLoad_{n,t} = pDemand_{n,t} ~ \forall{n,t} 
$$

### *eMaxProd*
$$
vGenProd_{g,t} \leq pGenAva_{n,g,t} \cdot pUnitCap_{g} \cdot vGenInv_{g} ~ \forall{n,g,t~|~pGenCon_{g} = n} 
$$

### *eMaxLineExp & eMaxLineImp*
$$
-pImpCap_{l} \leq vLineFlow_{l,t} \leq pExpCap_{l} ~ \forall{l,t} 
$$

### *Bounds*
$vGenProd_{g,t}\geq 0 ~ \forall g, t $

$vLossLoad_{n,t}\geq 0 ~ \forall n, t $

$vGenInv_{g} \in \mathbb{Z}^{+} ~ \forall g $
