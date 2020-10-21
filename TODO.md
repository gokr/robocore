
Add poster for end of LGE
Add user and channel state (loggers active)
Listen to adds and removes(?)
Volume calculations, logger delta?
New floor with two pools 
APY calcs
Implement predictions?
Whale tracking?
Graphs, perhaps grafana server side pngs


we need any mention of tacos when tagging the bot to spit back taco emojis :taco:

fpair1:
(poolK / (poolCORE + (10000 - poolCORE) * 0.997)) / 10000

flge:
(pool2K / ((10000-poolCORE) + (10000 - (10000-poolCORE)) * 0.997)) / 10000
-----------
fpair1:
(poolK / (poolCORE + (10000 - poolCORE) * 0.997)) / 10000

flge:
(pool2K / ((10000-poolCORE) + (10000 - (10000-poolCORE)) * 0.997)) / 10000

When all CORE is in the pools:

price1 = (poolETH / poolCORE)
price2 = (poolWBTC / (10000-poolCORE))

...and we have balance:

(poolETH / poolCORE) * priceETHinUSD = (poolWBTC / (10000-poolCORE)) * priceWBTCinUSD

...then:

poolCORE = (10000 * priceETHinUSD * poolETH) / (poolWBTC * priceWBTCinUSD + priceETHinUSD * poolETH)


# Selling CORE2ETH back into pair1 and rest into pair2
var newPoolETH = poolK / (poolCORE + (CORE2ETH) * 0.997);
var newPoolWBTC = poolK2 / (poolCORE2 + (10000 - poolCORE2 - poolCORE - CORE2WETH) * 0.997);

# Then price should be equal afterwards
var price1 = newPoolETH / (poolCORE + CORE2ETH)
var price2 = (newPoolWBTC / (10000 - poolCORE - CORE2ETH)) * priceBTCinETH

# So we want to know CORE2ETH
newPoolETH / (poolCORE + CORE2ETH) = newPoolWBTC / (10000 - poolCORE - CORE2ETH)

(poolK / (poolCORE + (CORE2ETH) * 0.997)) / (poolCORE + CORE2ETH) = (poolK2 / (poolCORE2 + (10000 - poolCORE2 - poolCORE - CORE2WETH) * 0.997)) / (10000 - poolCORE - CORE2WETH)

(k / (c + x * 0.997)) / (c + x) = (l / (d + (10000 - d - c - x) * 0.997)) / (10000 - c - x) * z


For k != l*z

zz = 0.000009*pow(c,2)*pow(l,2)*pow(z,2)+0.000018*c*l*d*k*z+119.64*c*l*k*z+119.64*l*d*k*z+397603600*l*k*z+0.000009*pow(d,2)*pow(k,2);

x1 = (-1.994 * c * k + 0.003*d*k+19940*k+1.997*c*l*z + sqrt(zz)) / (2 * (0.997*k-0.997*l*z));

x2 = (-1.994 * c * k + 0.003*d*k+19940*k+1.997*c*l*z - sqrt(zz)) / (2 * (0.997*k-0.997*l*z));



