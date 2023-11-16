---
title: 'Monthly timestep economic model of the southern MDB'
subtitle: ''
author:
- Neal Hughes, April Zhao
date: '16 November 2023'
bibliography: [resources/References.bib]  
figPrefix: 'figure'
tblPrefix: 'table'
eqPrefix: 'equation'
secPrefix: 'section'
numbersections: true 
header-includes: '\usepackage{bm}'
#csl: resources/style-manual-australian-government.csl
#/Applications/pandoc318/pandoc -s -o note.pdf note.md --pdf-engine /usr/local/texlive/2023/bin/universal-darwin/xelatex -F /Applications/pandoc318/pandoc-crossref --citeproc
#/Applications/pandoc318/pandoc -s -o note.docx note.md -F /Applications/pandoc318/pandoc-crossref --citeproc
#/Applications/pandoc318/pandoc -s -o note.html note.md  -F /Applications/pandoc318/pandoc-crossref --citeproc --mathjax
---

# Introduction {#intro}

This is a work in progress technical note detailing the potential set-up of a new monthly time-step economic model of irrigation activity, water demand and water trade in southern Murray-Darling Basin (MDB). This model would be an extension of the previous annual time-step model [@hughes2023economic](https://agupubs.onlinelibrary.wiley.com/doi/abs/10.1029/2022WR032559)

This model extends the previous version in a number of ways:

-   Monthly time-step rather than annual
-   Includes estimates of physical water demand (monthly river diversions)
-   Adds bio-physical water demand detail (i.e., evapotranspiration, soil moisture) similar to hydrological models
-   Structural economic model (i.e., profit maximization) rather than pure reduced-form

The model structure is an attempt to merge the bio-physical approach to water demand adopted in daily time-step hydrological models (such as the MDBA Murray source model) with a typical structural economic set-up (i.e., optimisation of profit subject to water and land constraints), while still keeping it relatively simple (i.e., small number of parameters) so that it can be fit to observed data. 

Some useful background:

[The MDBA Murray  / source water demand models](https://www.mdba.gov.au/sites/default/files/publications/crop-water-model-murray-lower-darling-2018.pdf)

[Allen et al. (1998)](https://www.fao.org/3/X0490E/x0490e00.htm)

[eWater source documentation](https://wiki.ewater.org.au/display/SD520/Irrigator+Demand+Model+-+SRG)

[MDBA irrigation area data](https://www.mdba.gov.au/sites/default/files/publications/irrigated-crop-area-data-for-the-lower-murray-darling-2003-to-2021.pdf)

[ABARES-UoM GovTeams site for HEMS](https://govteams.sharepoint.com/sites/hemshydroeconomicmodellingforthesouthernmdb)

# Variables and parameters

## Endogenous variables

| Variable          | Units        | Description                                                             |
| -----------       | -----------  | ----------------------------------------------------------------        |
| $W_{ijt}$         | ML           |  Water use in region $i$ for crop $j$ in period $t$                     |
| $L_{ijt}$         | Ha           |  Area of crop $j$ irrigated in region $i$ in period $t$                 |
| $\bar L_{ijt}$    | Ha           |  Potential area 'set-up' for crop $j$ in region $i$ in period $t$       |
| $Y_{ijt}$         | t            |  Quantity of production (i.e., yield$\times$area) for crop $j$ in region $i$ in period $t$       |
| $D_{it}$          | ML           |  River diversions in region $i$ in period $t$                           |
| $P^w_{it}$        | \$ / ML      |  Market price for water allocations in region $i$ period $t$            |
| $A_{it}$          | ML           |  Water allocations available for use (unused water) in region $i$ in period $t$                      |
| $T_{it}$          | ML           |  Net water allocation trade (import) in region $i$ in period $t$        |
| $U_{it}$          | ML           |  Usage of water allocation in region $i$ in period $t$                  |
| $\tilde W_{it}$   | ML           |  Net other water usage in region $i$ in period $t$                      |

## Exogenous / derived variables

| Variable          | Units        | Description                                                             |
| -----------       | -----------  | ----------------------------------------------------------------        |
| $ET^0_{it}$      | mm            |  Reference evapotranspiration for region $i$ in period $t$              |
| ${ER}_{t}$        | mm           |  Effective rainfall in region $i$ in period $t$  (excluding estimated run-off)                       |
| $w_{ijt}$         | ML / Ha      |  Water application rate for crop $j$ region $i$ in period $t$           | 
| $P^y_{jt}$        | \$ / t       |  Output price for crop $j$ in period $j$                                |
| $\Delta A_{it}$   | ML           |  New water allocations announced in region $i$ in period $t$            |
| $a_{it}$          | ML           |  Annual water allocation percentage in region $i$ in period $t$         |
| $E_{it}$          | ML           |  Water entitlement volume (available for consumptive use) in region $i$ in period $t$ |

## Known / derived parameters

| Parameter        | Description                                                                              |
| -----------      | ----------------------------------------------------------------                         |
| $K^c_{jm}$       |  Crop coefficient (monthly evapotranspiration factor) for crop $j$ in month $m$          |
| $k^c_{jm}$       |  Relative crop coefficient                                                               | 
| $k^s_{ijt}$      |  Potential water stress for crop $j$ in region $i$ in period $t$                         |

## Unknown parameters (to be estimated)

| Parameter               | Description                                                     |
|-------------------------|------------------------------------                             |
| $\beta^w_{ij}$          |  Crop water requirements parameter                              |
| $\beta^s_{ij}$          |  Crop water stress response parameter                           |
| $\beta^y_{ij}$          |  Crop yield response (maximum potential crop yield)             |
| $\beta^l_{ij}$          |  Crop yield response                                            |
| $\beta^{c0}_{ij}$       |  Annual cost per Ha of crop planted                             |
| $\beta^{c1}_{ij}$       |   Cost of water use per ML (i.e. delivery cost)                  |
| $\beta^{d0}_{i}$        |  Minimum (non-irrigation) water diversions                      |
| $\beta^{d1}_{i}$        |  Diversions response to irrigation water use                    |
| $\beta^{\tilde w0}_{i}$, $\beta^{\tilde w1}_{i}$|  Parameters for the net benefit of other water use function |


# Data 

- For now regions can be the same as the previous ABARES model regions (catchment areas)
- Crop types would be the same as previous ABARES model except with Other cereals, Other broadacre and Other crops combined into a single category
- Crop coefficients could be the ones from QJ's study 
  - For Rice we can add some soil moisture targets as follows:
    - 50 mm in the crop planting month (October)
    - -50mm in the last month (March)
- Annual data for $W$, $L$, $Y$, $P^y$ and $P^w$ by region and crop can come from the ABARES catchment dataset. Some modifications may be required:
  - Aggregating other cereals/broadacre and crops
  - For Pasture we could try setting $Y$ to 1, and $P^y$ equal to a fodder price index
  - For other crops we could set $P_y$ to the price of wheat, then divide GVIAP for these activities by $P_y$ to derive a quantity index....
- Monthly ET and ER data to be provided by UoM. Hoping UoM can also provide run-off data which we can subtract from ER.
- Monthly data on water usage $U$ to come from state water accounting data (still not yet available for SA)
  - Still yet to confirm if this usage includes usage against environmental entitlements

# Model equations 

The model is defined over three sets: regions $i$, irrigation crops $j$ and time $t$. The time-step is monthly, although some variables operate at an annual time-step (i.e., crop production and profit). Further some monthly variables (such as water use) may only have data available at an annual time-step. 

Below $t$ is used interchangeably to refer to annual or monthly depending on the context. Where monthly data is summed to generate annual data, this is denoted as $\sum_m$ where $m$ is used to index the months of the year.

Sometimes where we refer to months across the cropping season within a single year we denote the crop planting month $t=m$ and the crop harvest month $t=h$.

We define the set of all crop types $J$, the set of perennial crops $\bar J$, annual $\dot J$ and opportunistic crops $\tilde J$.

## Water demand

### Crop water requirements

Following standard hydrological approaches short-term crop water requirements are determined by bio-physical drivers. Specifically, target (i.e., maximum) water application rates $w_{ijt}$ for crop $i$ in region $i$ in period $t$ are a function of potential crop evapotranspiration (ET) and effective rainfall $ER_{it}$:

$$w_{ijt} = \frac{1}{100}.\beta^{w}_{ijt} \max \left({K^c_{jm}ET^0_{it} - ER_{it},   }, 0\right) $$ 

Here $K^c_{ijt}$ are pre-defined 'crop coefficients' and ${ET}^0_{it}$ is the reference ET for region $i$ in period $t$ (with both $ET^0_{ijt}$, and ${ER}_{it}$ being exogenous functions of weather data). Following hydrological model conventions, crop water requirements $K^c_{jm}ET^0_{ijt} - ER_{it}$ are defined in mm units (and converted to ML by dividing by 100).

This approach differs from official hydrological models (i.e., Murray SOURCE model) in two key respects: the time-step is monthly rather than daily and there is no explicit soil moisture balance. While recent research (QJ etc.) has shown this simple approach can achieve reasonable performance, some adjustments are adopted to improve accuracy further. Firstly, ER data used adjusted to remove estimated monthly run-off. Secondly, for rice crops water requirements are adjusted to account for poundage, by adding a soil moisture recharge / depletion target:

$$w_{ijt} = \frac{1}{100}.\beta^{w}_{ijt} \max \left({K^c_{jm}ET^0_{it} + SM_{jt} - ER_{it},   }, 0\right) $$ 

Note that this approach does not allow for deficit irrigation where water application rates are less than the target rate $w_{ijt}$. However, as detailed below there is flexibility to vary the area irrigated (to only irrigate a portion of the planted area) as outlined below.

### Crop areas and production

Marginal crop productivity (i.e., marginal crop yield in t / ha) is assumed to be linearly decreasing in area planted. Production (t) is the integral of marginal crop yield with respect to area planted, such that crop production is a quadratic function $f^y_{ij}$: 

$$\begin{aligned}f^y_{ij} \left(L_{ijt} \right)  &= \int_0^{L_{ijt}}\beta^y_{ij} \left(1 - \frac{ L_{ijt}}{\beta^l_{ij}\bar L_{ijt}} \right)\\
                                                & = \beta^y_{ij} \left({L_{ijt}} - \frac{L^2_{ijt}}{2.\beta^l_{ij}\bar L_{ijt}}  \right) \end{aligned}$$

This quadratic relationship ensures both that short-run water demands are downward sloping (i.e., decreasing in water prices) and that each region plants a realistic variety of crop types (rather than planting all land to the single most profitable crop). Here $\bar L_{ijt}$ reflects the maximum potential area available / set-up for crop type $i$ in region $j$ in period $t$.

#### Perennial crops

Crop types $j$ belong to one of three categories: perennials, annuals (summer crops) or 'opportunistic'. For perennials (i.e., fruit and nut trees, wine grapes) area planted is assumed fixed for all $t$ but the area irrigated $L^w_{ijt}$ can be varied each month:

$$\bar L_{ijt} = L_{ijt} $$
$$W_{ijt} = L^w_{ijt} w_{ijt} $$
$$L^w_{ijt} \leq L_{ijt} $$

Any crop areas not irrigated are subject to water stress and yield penalties. A linear crop yield response to water stress is adopted similar to that in hydrological models (Source User Guide, Allen et al. 1998). Here water stress (for any land not irrigated) $k^s_{ijt}$ is increasing in ET and decreasing in effective rainfall, with $k^s_{ijt}$ = 0, if $ER_{it} \geq K^c_{jm}ET^0_{ijt}$:

$$k^s_{ijt} = \beta^s_{ij}\left(1 - \frac{\min\left[ER_{it}, K^c_{jm}ET^0_{it}\right]} {K^c_{jm}ET^0_{it}} \right) $$

As detailed below, annual production for each irrigated crop is a function of both area planted $L_{ijt}$ and any monthly water stress.   In the absence of water stress ($L_{ijt} = L_{ijt}^w$ and $k^s_{ijt} = 0$ for all $t$) crop production $Y_{ijt} = f^y_{ij} \left(L_{ijt}\right)$. In any months with water stress crop penalties proportional to $k^{s}_{ijt}$ are incurred. Note the below approach simplifies the standard (Allen et al. 1998) approach slightly by assuming water stress in each month has an independent additive effect on yields (ensuring that short-run crop yield responses and water demands are independent of past & future months):

$$\begin{aligned} y_{ijt} &= \sum_m  k_{mj} \Big(  f^y_{ijt} \left(L^w_{ijt} \right) + \left(1 - k_{ijt}^s \right)  \Big( f^y_{ijt} \left(L_{ijt} \right) - f^y_{ijt} \left(L^w_{ijt} \right) \Big)\Big) \\
                          &= f^y_{ij} \left(L_{ijt}\right) - \sum_m  k_{mj} .k^{s}_{ijt}  \left( f_{ijt}^y \left(L_{ijt} \right) - f_{ijt}^y \left(L^w_{ijt} \right) \right)
                          \end{aligned}$$

$$ Y_{ijt} = \max \left[ y_{ijt}, 0 \right], Y'_{ijt} = \min \left[ y_{ijt}, 0 \right] $$

$$k_{mj} = \left( \frac{K^c_{jm}}{\sum_m K^c_{jm}} \right), \sum_m k_{mj} = 1$$

Here an allowance is also made for 'carryover yield' penalties: where water stress is severe enough to impact future yields (e.g., damage tree crops). In these cases $\beta^s_{ij}$ (and therefore $k^s_{ijt}$) can be greater than 1 and $\tilde Y_{ijt}$ can be negative. Here $Y'_{ijt}$ can be interpreted as a penalty representing (expected discounted) future lost production (and/or related costs such as re-planting etc.) due to current season water stress.


#### Opportunistic crops

With opportunistic activities (e.g., pasture, hay, vegetables, hay and other crops) the extent of irrigation $L^w_{ijt}$ can vary on a monthly basis, subject to a fixed annual upper limit $\bar L_{ijt}$. In the case of pasture and winter crops for example, the upper limit can be viewed as the total area planted and able to be irrigated (of which in any month some proportion may be irrigated and some proportion dry-land).

From a model perspective, these activities operate more or less identically to perennial crops as outlined above, accept that $\bar L_{ijt}$ is not defined by observed $L_{ijt}$ data but an assessment of potential irrigable area (and observed annual irrigation area data is assumed to reflect the maximum of monthly area irrigated over the year: $\max_{m \in t} L^w_{ijt}$).

$$\bar L_{ijt} \geq L_{ijt} $$
$$W_{ijt} = L^w_{ijt} w_{ijt} $$
$$L^w_{ijt} \leq \bar L_{ijt} $$
$$L_{ijt} = \max_{m \in t} L^w_{it}$$

#### Annual (summer) crops

For annual (summer) crops (e.g., rice and cotton), area planted is chosen each year in a defined planting month, $m$. After planting (up until the harvest month $h$) crop areas can be reduced but not increased (i.e., parts of the planted area can be abandoned), such that:

$$Y_{ij,t} = f^y_{ij} \left(L_{ij,h}\right)$$
$$L_{ij,h} \leq L_{ij, h-1} \leq ...  \leq L_{ij,m} \leq \bar L_{ijt}$$

### Water supply

$$A_{i,t+1} = A_{it} + \Delta A_{it} - U_{it} + T_{it} - F_{it}$$

$$\Delta A_{it} = \sum_h (a_{hi,t+1} - a_{hit}).E_{hit}$$

$$U_{it} = \sum_j W_{jit} + \tilde W_{it}$$

More to be added.

### Diversions

Regional monthly diversions are a linear function of total water allocation use, with the parameters helping to account for additional sources of diversions (i.e., delivery losses, urban / non-regulated water use) in each region.

$$D_{it} = \beta^{d0}_{im} + \beta^{d1}_{im} U_{it}$$

### Farm profits

Annual profits from irrigation water use $\pi_{it}$ in region $i$ in year $t$ are defined as:

$$ \pi_{it} = \sum_j P^y_{jt}.y_{ijt} - \sum_j \beta^{c0}_{jt}L'_{ijt} - \sum_j \sum_{m \in t}(P^w_{it} + \beta^{c1}_{ij}) W_{ijm} + f^{\tilde w}(\tilde W_{it}) - {P}^{w} \tilde{W}_{it} $$

$$ f^{\tilde w} \left( \tilde W_{it} \right) =  \beta^{\tilde w0}_{im}\tilde W_{it} - \frac{1}{2}\beta^{\tilde w1}_{i}\tilde W_{it}^2$$

$$L'_{ijt} = \begin{cases}
            \bar L_{ijt} & \text{if $j \in \bar J, \tilde J$};\\
            L_{ijm} & \text{if $j \in \dot J$}
            \end{cases}$$

Here regional profits $\pi_{it}$ are equal to revenue from crop production less costs: including annual area-based costs $\beta^{c0}_{jt}$ and monthly water costs. Annual area-based costs are incurred at the time of planting in the case of annual crops, and are fixed annual costs in the case of perennials. Water costs include both the market price of water $P^w_{it}$ and any usage / delivery costs $\beta^{c1}_{ij}$. 


Note that profits are defined net of any yield penalties $P^y_{jt}Y'_{ijt}$ (which are embedded in the term $\sum_j P^y_{jt}.y_{ijt}$).

In addition, profits include the net benefits of 'other water use' $f^{\tilde w}$. Other water use reflects allocation use beyond that applied to crops (for example water placed into on-farm storages, or used for non-agricultural purposes). Other water use can also be negative, in which case it reflects water taken from other sources (e.g., groundwater, farm dams) and applied to crops (in this case $f^{\tilde w}$ reflects the costs of extracting these alternative water sources).

# Estimation


## Parameter starting values

Most of the model parameters have simple interpretations and logical starting values:

* $\beta^l_{ij} \geq 1$ (perhaps start with 2, noting that any values less than 1 imply that the true maximum area is less than $\bar L$) 
* $\beta^w_{ij} = 1$ (or could be estimated from historical data such that $w_{ijt} \geq W_{ijt} / L_{ijt}$)
* $\beta^s_{ij} = 1$ (perhaps 2 for perennials to allow for some yield penalties)
* $\beta^y_{ij}$ can be set using historical data such that $\beta^y_{ijt} > Y_{ijt} / L_{ijt}$ (perhaps 1.5 * maximum observed yield)
* $\beta^{c0}, \beta^{c1}$ could be estimated from irrigation survey data via a cost regression (i.e., total cash costs against crop areas and water use) 
* Starting values for $\beta^{d0}_{im}, \beta^{d1}_{im}$ could be obtained by OLS regression of diversion and allocation use data. 
* Starting values for $\beta^{\tilde w0}_{im}, \beta^{\tilde w1}_{im}$ could be obtained by OLS regression of annual 'other water' estimates  


## Econometric estimation

Once a set of starting values have been obtained, parameter estimates could then be obtained by deriving the model reduced-form / first order conditions, and then fitting this system of equations to the available historical data (i.e., find the set of parameters which minimises the sum of squared residuals).

### Model reduced form

With the inclusion of yield penalties the profit function can be defined as:

$$\begin{aligned}\pi_{it} = \sum_j P^y_{jt}\left(\sum_m  k_{mj} \Big(  \left(1 - k_{ijt}^s \right) f_{ijt} \left(L_{ijt} \right)  +  k^s_{ijt}f_{ijt} \left(L^w_{ijt} \right) \Big)\right) - \\ 
\sum_j \Big(\beta^{c0}_{ij}L'_{ijt} + (P^w_{it} + \beta^{c1}_{ij}) W_{ijt}\Big)  + f^{\tilde w}(\tilde W_{ij}) - P^w \tilde W_{it} \end{aligned}$$


- Water use FOC / short-run water demand function (perennials and opportunistic):

$${\frac{\partial \pi_{it}}{\partial W_{ijm}}} = 0 $$

$$P_{im}^w + \beta^{c1}_{ijm} = \left( \frac{P^y_{jt} k_{mj}\beta^y_{ij}k^s_{ijm}}{w_{ijm} }\right)\left( 1 - \frac{W_{ijt}}{\beta_{ij}^l\bar L_{ijt} w_{ijm} } \right)$$

$$W_{ijm} =  w_{ijm} \beta_{ij}^l\bar L_{ijt}\left(1- \frac{(P_{it}^w + \beta^{c1}_{ijm}) w_{ijt}}{P^y_{jt} k_{mj}\beta^y_{ij} k^s_{ijm}} \right)$$

$$0 \leq W_{ijt} \leq \bar L_{ijt}w_{ijm} $$

- Water use FOC / short-run water demand function (annuals):

$$\frac{\partial \pi_{it}}{\partial L_{ijs}} = 0 \text{ and } L_{ijs} \leq L_{ij,s-1} \leq \bar L_{ijt} $$

$$\mathbf{E}_{t=s} \left[ \sum_{t=s}^h  {w_{ijt}}(\beta^{c1}_{ij} + P^w_{it} )  \right]= \mathbf{E}_{t=s}\left[ P^y_{jt}\beta^y_{ij}   \left(1 - {L_{ijh}}.\frac{1}{\beta^l_{ij} \bar L_{ijt}}\right)  \mid L_{ijs}\right] $$

$$ \sum_{t=s}^h  \mathbf{E} \left[{w_{ijt}}  (\beta^w_{ij} + P^s_{it} ) \right ].(1-\Pr[L_{ijt}<L_{ijs}]) =  (1-\Pr[L_{ijh}<L_{ijs}]).P^y_{jt}\beta^y_{ij}   \left(1 - {L_{ijs}}.\frac{1}{\beta^l_{ij} \bar L_{ijt}}\right) $$

With an assumption of full irrigation of crop area from this point on, and known future water prices $P_{it}^w = P_{im}^w$: 

$$ \sum_{t=s}^h  \mathbf{E}_{t=s} \left[{w_{ijt}} \right] (\beta^{c1}_{ij} + P^s_{it} ) = P^y_{jt}\beta^y_{ij}   \left(1 - {L_{ijs}}.\frac{1}{\beta^l_{ij} \bar L_{ijt}}\right) $$

$$ W_{ijs} = w_{ijs} \beta^l_{ij} \bar L_{ijt}\left( 1 - \frac{\sum_{t=s}^h  \mathbf{E}_{t=s} \left[{w_{ijt}} \right] (\beta^{c1}_{ij} + P^w_{is} )}{P^y_{jt}\beta^y_{ij}}   \right)$$

$$0 \leq W_{ijs} \leq L_{ij,s-1}w_{ijs} $$

- Crop planted area FOC / land demand function (annuals):

$$\frac{\partial \pi_{it}}{\partial L_{ijm}} = 0, 0 \leq L_{ijm} \leq \bar L$$

$$\mathbf{E_{t=m}} \left[ \beta^{c0}_{ijt} + \sum_{t=m}^{h}  {w_{ijt}}(\beta^{c1}_{ij} + P^w_{it} )  \right] = \mathbf{E}_{t=m}\left[ P^y_{jt}\beta^y_{ij}   \left(1 - {L_{ijh}}.\frac{1}{\beta^l_{ij}}\right) \right] $$

$$ \beta^{c0}_{ijt} + \sum_{t=m}^{h}  \mathbf{E_{t=s}} \left[{w_{ijt}}(\beta^{c1}_{ij} + P^w_{it} )  \right].(1-\Pr[L_{ijt}<L_{ijs}]) =  P^y_{jt}\beta^y_{ij}   \left(1 - \frac{{L_{ijh}}}{\beta^l_{ij}}\right).(1-\Pr[L_{ijh}<L_{ijm}])  $$

With an assumption of full irrigation of crop area to harvest time (i.e., $\Pr[L_{ijh}<L_{ijm}] = 0$) and known future water prices $P_{it}^w = P_{im}^w$: 

$$ \beta^{c0}_{ijt} + \sum_{t=m}^{h}  \mathbf{E_{t=s}} \left[{w_{ijt}} \right](\beta^{c1}_{ij} + P^w_{it} )  =  P^y_{jt}\beta^y_{ij}   \left(1 - \frac{{L_{ijh}}}{\beta^l_{ij} \bar L_{ijt}}\right)  $$

$$ L_{ijs} =  \beta^l_{ij} \bar L_{ijt} \left( 1 - \frac{ \beta^{c0}_{ijt} + \sum_{t=m}^h  \mathbf{E}_{t=s} \left[{w_{ijt}} \right] (\beta^{c1}_{ij} + P^w_{im} )}{P^y_{jt}\beta^y_{ij}}  \right)$$

$$0 \leq L_{ijs} \leq \bar L_{ijm} $$

- Other water use FOC / short-run other water demand function:

$$\frac{\partial \pi_{it}}{\partial \tilde W_{ijt}} = 0  $$

$$\tilde W_{it} = {\frac{1}{\beta^{\tilde w^1}_{im}}} \left( \beta^{\tilde w0}_{im} - P_{it}^w \right)$$

### Econometric estimation

Given some starting values the parameters can be estimated using historical data. The problem can be set up as a non-linear least squares minimisation problem (see below). The objective function will require some weights $\delta$ to normalise the different variables, one option is to set the weights as the inverse of the standard deviation of the target variable.

Note that the land use equation is different for annuals and perennials. For perennials we want to compare the max. of $L^w$ across the year with the observed (since $L_w$ will vary for different months within the year). For annual crops we want to compare the initial planted area (from the planting month $m$) with the observed.

We would probably need to exclude pasture data from the yield equation and error function.

$$\begin{aligned} &\epsilon^2 = \delta_W \sum_t \sum_i \sum_j \left( W_{ijt} - \sum_{m \in t} \hat W_{ijm}\right)^2  + \\    
                  &\left[ \delta_{L1} \sum_t \sum_i \sum_{j \in \dot J} \left( L_{ijt} - \hat L_{ijm}\right)^2 \right]_{j \in \dot J} +   \\
                  &\left[ \delta_{L2} \sum_t \sum_i \sum_{j \in \bar J, \tilde J} \left( L_{ijt} - \max_{m \in t} \hat L_{ijt}^w\right)^2 \right]_{j \in \tilde J} + \\
                  &\delta_{Y}  \sum_t \sum_i \sum_j \left( Y_{ijt} - \hat Y_{ijt}\right)^2 + \\
                  &\delta_{\tilde W}  \sum_t \sum_i \left( \sum_j \tilde W_{ijt} - \sum_{m \in t} \hat {\tilde W}_{it}  \right)^2 + \\
                  &\delta_{D}  \sum_t \left( D_{it} - \hat {D}_{it}\right)^2 \end{aligned}
$$

$$\min_{ \vec {\beta}} \epsilon^2$$

$$\vec {\beta} = \{ \beta^w_{ij}, \beta^s_{ij}, \beta^y_{ij}, \beta^l_{ij}, \beta^{c0}_{ij}, \beta^{c1}_{ij}, \beta^{d0}_{i}, \beta^{d1}_{i}, \beta^{\tilde w0}_{i}, \beta^{\tilde w1}_{i} \} $$

Subject to:

$$\begin{aligned} \hat W_{ijm} & =  w_{ijm} \beta_{ij}^l \bar L_{ijm}\left(1- \frac{(P_{it}^w + \beta^{c1}_{ijm}) w_{ijt}}{P^y_{jt} k_{mj}\beta^y_{ij} k^s_{ijm}} \right) & \qquad j \in \bar J, \tilde J \\
& \qquad 0 \leq \hat W_{ijt} \leq \bar L_{ijt}w_{ijt} \qquad \qquad & \qquad \text{ } \\ \\
\hat L^w_{ijt} &= \hat W_{ijt} / w_{ijt}  & \qquad j \in \tilde J \\ \\
\hat L_{ijm} &= \beta^l_{ij} \bar L_{ijt} \left( 1 - \frac{ \beta^c_{ijt} + \sum_{t=m}^h  \mathbf{E}_{t=m} \left[{w_{ijt}} \right] (\beta^{c1}_{ij} + P^w_{im} )}{P^y_{jt}\beta^y_{ij}}  \right) & \qquad j \in {\dot J} \\
& \qquad 0 \leq L_{ijm} \leq \bar L_{ijt} \\ \\
\hat W_{ijs} &= w_{ijs} \beta^l_{ij} \bar L_{ijt} \left( 1 - \frac{\sum_{t=s}^h  \mathbf{E}_{t=s} \left[{w_{ijt}} \right] (\beta^{c1}_{ij} + P^w_{is} )}{P^y_{jt}\beta^y_{ij}}   \right) & \qquad j \in {\dot J} \\
\hat L_{ijs} & = \hat W_{ijs} / w_{ijs}\\
& \qquad 0 \leq \hat W_{ijs} \leq \hat L_{ij,s-1}w_{ijs} \\ \\
Y_{ijt} &= f^y_{ij} \left (L_{ijh} \right) & \qquad j \in {\dot J}\\
Y_{ijt} &= \sum_m  k_{mj} \Big(  \left(1 - k_{ijt}^s \right) f^y_{ijt} \left(\bar L_{ijt} \right)  +  k^s_{ijt}f^y_{ijt} \left(L^w_{ijt} \right) \Big) & \qquad j \in {\tilde{J}, \bar J}\\
 & Y_{ijt} \geq 0\\
 & f^y_{ij} \left (L_{ijt} \right) = \beta^y_{ij} \left({L_{ijt}} - \frac{L^2_{ijt}}{2.\beta^l_{ij}\bar L_{ijt}}  \right) \\ \\
\hat{\tilde W}_{it} &= {\frac{1}{\beta^{\tilde w^1}_{i}}} \left( \beta^{\tilde w0}_{im} - P_{it}^w \right)\\
\hat D_{it} &= \beta^{d0}_{im} + \beta^{d1}_{im} (\hat W_{it} + \hat{ \tilde W}_{it})\\ \\
\end{aligned}$$


Notice that calculating the water and land use conditions for annual crops requires pre-computing expected $w_{ijt}$. The easiest option is to calculate long-run average $w_{ijm}$ for every month and store this. Another option would be to estimate a conditional expectation for remaining months given knowledge of $w_{its}$ as a series of OLS regressions on the historical data (i.e., $w_{ijt} = \beta_0 + \beta_1.w_{ijs}$) storing the parameters.

In future it may be worth setting some more constraints on the parameters such as:

$$\beta > 0, \text{ for all } \beta \in \vec{\beta}$$

$$0.8 \leq \beta^w \leq 1.2 $$

$$1 \leq \beta^l $$

We may also want to allow some parameters to have a linear time trend, in which case the parameter $\beta$ in the above equations would be replaced with $\beta_0$ + $\beta_1.t$. In other cases parameters need to vary monthly $(\beta_{im}^{d0}, \beta_{im}^{d1}, \beta_{im}^{\tilde w0})$: these will need to be included in the above equations with monthly dummy variables.

## Model-based (aka structural) estimation

To be added

## Solving the Model





# References {.unnumbered}

