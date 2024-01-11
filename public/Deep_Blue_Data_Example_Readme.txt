Date: 10 September, 2021

Dataset Title: Modeled Response of Greenland Snowmelt to the Presence of Biomass Burning-Based Absorbing Aerosols in the Atmosphere and Snow

Dataset Creators: J.L. Ward, M.G. Flanner, M. Bergin, J.E. Dibb, C.M. Polashenski, A.J. Soja, & J.L. Thomas

Dataset Contact: Jamie Ward jamiewa@umich.edu

Funding: NNX14AE72G (NASA), DE-SC0013991 (DOE), & 80NSSC17K0323 (NASA Earth and Space Science Fellowship, NESSF)

Key Points:
- We compare the effects of in-snow and atmospheric light-absorbing aerosols on Greenland's climate.
- Atmospheric light-absorbing aerosols warm the troposphere and dim the surface, which causes non-linear snowmelt changes across Greenland.
- For qualitatively similar burdens, snowmelt on Greenland is more sensitive to in-snow light-absorbing aerosols than atmospheric aerosols.

Research Overview:
Biomass burning produces smoke aerosols that are emitted into the atmosphere.  Some smoke constituents, notably black carbon (BC), are highly effective light-absorbing aerosols (LAA).  Emitted LAA can be transported to high albedo regions like the Greenland Ice Sheet (GrIS) and affect local snowmelt.  In the summer, the effects of LAA in Greenland are uncertain. To explore how LAA affect GrIS snowmelt and surface energy flux in the summer, we conduct idealized global climate model simulations with perturbed aerosol amounts and properties in the GrIS snow and overlying atmosphere.  The in-snow and atmospheric aerosol burdens we select range from background values measured on the GrIS to unrealistically high values.  This helps us explore the linearity of snowmelt response and to achieve high signal-to-noise ratios.  With LAA operating only in the atmosphere, we find no significant change in snowmelt due to the competing effects of surface dimming and tropospheric warming.  Regardless of atmospheric LAA presence, in-snow BC-equivalent mixing ratios greater than ~60 ng/g produce statistically significant snowmelt increases over much of the GrIS.  We find that net surface energy flux changes correspond well to snowmelt changes for all cases.  The dominant component of surface energy flux change is solar energy flux, but sensible and longwave energy fluxes respond to temperature changes.  Atmospheric LAA dampen the magnitude of solar radiation absorbed by in-snow LAA when both varieties are simulated.  In general, the significant melt and surface energy flux changes we simulate occur with LAA quantities that have never been recorded in Greenland.

Methodology:
The data are model output form climate simulations conducted with the Community Earth System Model (CESM) version 1.0.3.
Date Coverage: 2018-2030 (Date range include dates of input data to model (2018-2020), and dates of simulated outputs with various simulation types).
Instrument and/or Software specifications: NA

Files contained here:
The folders show divisions based on each simulation conducted. Each folder contains 60 netcdf files (30 with atmospheric output and 30 with land model output) for June, July, and August (JJA) over 10 simulation years. The folders and simulations are described below:
- CONTROL: The CONTROL simulation zeroed out all LAA in the atmosphere and in the snow (AOD=0, BCE=0.0ng/g). Filename prefix = grn_aer01
AOD folders: Atmosphere-only aerosol simulations (termed AOD-ONLY in the manuscript).  Single-scatter albedo is held constant for all runs (SSA=0.93).
- AOD_009: AOD = 0.09 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer02.
- AOD_021: AOD = 0.21 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer03.
- AOD_050: AOD = 0.50 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer08 (also used for VSSA = 0.93 case).
- AOD_075: AOD = 0.75 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer13.
- AOD_100: AOD = 1.0 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer14.
BCE folders: In-snow-only aerosol simulations (termed IN-SNOW in the manuscript). We compute BCE (BCE = Black Carbon Equivalent) for dust and black carbon combinations in the manuscript.
- BCE_0027: BCE = 2.7ng/g remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer04.
- BCE_0157: BCE = 15.7ng/g remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer05.
- BCE_0618: BCE = 61.8ng/g remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer09.
- BCE_0928: BCE = 92.8ng/g remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer15.
- BCE_1237: BCE = 123.7ng/g remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer16.
BOTH folders: Atmospheric and in-snow aerosols are modeled simultaneously (for more information, see the manuscript).
- BOTH_009_0027: AOD = 0.09 and BCE = 2.7ng/g remain constant within the Greenland domain for the entire simulation (in the atmosphere and in the snow, respectively). Filename prefix = grn_aer06.
- BOTH_021_0157: AOD = 0.21 and BCE = 15.7ng/g remain constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer07.
- BOTH_050_0618: AOD = 0.50 and BCE = 61.8ng/g remain constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer10.
- BOTH_075_0928: AOD = 0.75 and BCE = 92.8ng/g remain constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer17.
- BOTH_100_1237: AOD = 1.0 and BCE = 123.7ng/g remain constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer18.
VSSA folders: VSSA (Variable single-scatter albedo) simulations test the effects of changing atmospheric LAA single-scatter albedo.  These simulations are like the AOD-ONLY simulations except AOD is held constant (AOD = 0.50) and SSA is changed.
- VSSA_90_AOD_050: SSA = 0.90 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer11_ssalow.
- VSSA_96_AOD_050: SSA = 0.96 remains constant within the Greenland domain for the entire simulation. Filename prefix = grn_aer12_ssahi.
Related publication(s):
Ward, J.L., et al. (2018). Modeled Response of Greenland Snowmelt to the Presence of Biomass Burning-Based Absorbing Aerosols in the Atmosphere and Snow. Forthcoming.

Use and Access:
This data set is made available under a Creative Commons Public Domain license (CC0 1.0).

To Cite Data:
Ward, J.L., Flanner, M.G., Bergin, M., Dibb, J.E., Polashenski, C.M., Soja, A.J., & Thomas, J.L. (2018). Modeled Response of Greenland Snowmelt to the Presence of Biomass Burning-Based Absorbing Aerosols in the Atmosphere and Snow [Data set]. University of Michigan - Deep Blue. https://doi.org/10.7302/Z24Q7S64
