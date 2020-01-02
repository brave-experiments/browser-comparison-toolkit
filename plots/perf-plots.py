import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import rcParams
rcParams.update({'figure.autolayout': True})
rcParams.update({'figure.autolayout': True})
rcParams.update({'errorbar.capsize': 4})
from pylab import *
import pickle
import pandas as pd

%matplotlib inline


# global parameters
width = 0.3   # width for barplot
bar_colors   = ['orange', 'red']

# increase font
font = {'weight' : 'medium',
        'size'   : 14}
matplotlib.rc('font', **font)

perf=pd.read_csv('bench_perf_macos.csv')
# perf = perf.dropna()
perf[['browser', 'page type', 'loadEvent.median', 'fullyLoaded.median']].groupby(['browser', 'page type'])
grouped = perf[['browser', 'page type', 'loadEvent.median', 'fullyLoaded.median']].groupby(['browser', 'page type'])

load = grouped.mean().reset_index()
err = grouped.std().reset_index()

load = load.loc[(load['page type'] == 'article')].append(
    load.loc[(load['page type'] == 'landing')]).append(
    load.loc[(load['page type'] == 'ecommerce')])

err = err.loc[(err['page type'] == 'article')].append(
    err.loc[(err['page type'] == 'landing')]).append(
    err.loc[(err['page type'] == 'ecommerce')])

barWidth = 0.2
r1 = np.arange(len(load[(load['browser'] == 'Brave')]))
r2 = [x + barWidth for x in r1]
r3 = [x + barWidth for x in r2]
r4 = [x + barWidth for x in r3]

bar_colors   = ['orange', 'green', 'red', 'purple']
workload = ['News Articles', 'News Homepage', 'Shopping']
browser_list = ['Brave', 'Chrome', 'Opera', 'Firefox']
# plt.figure(figsize=(11, 9))
fig, (ax_plt, ax_flt) = plt.subplots(1, 2, sharey=True)
# fig.suptitle('Windows Performance', fontsize=24)
fig.set_size_inches(11, 5)
ax_plt.set_xticks([x + barWidth*1.5 for x in r1])
ax_plt.set_xticklabels(workload, fontsize = 14, rotation = 0)
legend_lines = []
legend_lines.append(Line2D([0], [0], color = bar_colors[0], lw = 2))
legend_lines.append(Line2D([0], [0], color = bar_colors[1], lw = 2))
legend_lines.append(Line2D([0], [0], color = bar_colors[2], lw = 2))
legend_lines.append(Line2D([0], [0], color = bar_colors[3], lw = 2))
ax_plt.legend(legend_lines, browser_list)
ax_plt.title.set_text('Page Load Time (s)')
ax_plt.bar(x = r1,
    height = load[(load['browser'] == 'Brave')]['loadEvent.median'] / 1000,
    yerr = err[(err['browser'] == 'Brave')]['loadEvent.median'] / 1000,
    width=barWidth,
    color = bar_colors[0])
ax_plt.bar(x = r2,
    height = load[(load['browser'] == 'Chrome')]['loadEvent.median'] / 1000,
    yerr = err[(err['browser'] == 'Chrome')]['loadEvent.median'] / 1000,
    width=barWidth,
    color = bar_colors[1])
ax_plt.bar(x = r3,
    height = load[(load['browser'] == 'Opera')]['loadEvent.median'] / 1000,
    yerr = err[(err['browser'] == 'Opera')]['loadEvent.median'] / 1000,
    width=barWidth,
    color = bar_colors[2])
ax_plt.bar(x = r4,
    height = load[(load['browser'] == 'Firefox')]['loadEvent.median'] / 1000,
    yerr = err[(err['browser'] == 'Firefox')]['loadEvent.median'] / 1000,
    width=barWidth,
    color = bar_colors[3])


ax_flt.set_xticks([x + barWidth*1.5 for x in r1])
ax_flt.set_xticklabels(workload, fontsize = 14, rotation = 0)
legend_lines = []
legend_lines.append(Line2D([0], [0], color = bar_colors[0], lw = 2))
legend_lines.append(Line2D([0], [0], color = bar_colors[1], lw = 2))
legend_lines.append(Line2D([0], [0], color = bar_colors[2], lw = 2))
legend_lines.append(Line2D([0], [0], color = bar_colors[3], lw = 2))
ax_flt.legend(legend_lines, browser_list)
ax_flt.title.set_text('Fully Loaded Time (s)')
ax_flt.bar(x = r1,
    height = load[(load['browser'] == 'Brave')]['fullyLoaded.median'] / 1000,
    yerr = err[(err['browser'] == 'Brave')]['fullyLoaded.median'] / 1000,
    width=barWidth,
    color = bar_colors[0])
ax_flt.bar(x = r2,
    height = load[(load['browser'] == 'Chrome')]['fullyLoaded.median'] / 1000,
    yerr = err[(err['browser'] == 'Chrome')]['fullyLoaded.median'] / 1000,
    width=barWidth,
    color = bar_colors[1])
ax_flt.bar(x = r3,
    height = load[(load['browser'] == 'Opera')]['fullyLoaded.median'] / 1000,
    yerr = err[(err['browser'] == 'Opera')]['fullyLoaded.median'] / 1000,
    width=barWidth,
    color = bar_colors[2])
ax_flt.bar(x = r4,
    height = load[(load['browser'] == 'Firefox')]['fullyLoaded.median'] / 1000,
    yerr = err[(err['browser'] == 'Firefox')]['fullyLoaded.median'] / 1000,
    width=barWidth,
    color = bar_colors[3])
# plt.show()
plt.savefig('perf_macos.png')


def cdfplot_new(data, ax):
    num_bins = 20
    counts, bin_edges = np.histogram (data, bins=num_bins, normed=True)
    cdf = np.cumsum (counts)
    curve = ax.plot (bin_edges[1:], cdf/cdf[-1])
    return curve

style       = ['solid', 'dashed', 'dotted']              # styles of plots  supported

brave = perf[(perf['browser'] == 'Brave')][['url', 'loadEvent.median', 'fullyLoaded.median']].set_index('url')
chrome = perf[(perf['browser'] == 'Chrome')][['url', 'loadEvent.median', 'fullyLoaded.median']].set_index('url')
firefox = perf[(perf['browser'] == 'Firefox')][['url', 'loadEvent.median', 'fullyLoaded.median']].set_index('url')
opera = perf[(perf['browser'] == 'Opera')][['url', 'loadEvent.median', 'fullyLoaded.median']].set_index('url')

chrome_speedup = chrome.subtract(brave).dropna()
firefox_speedup = firefox.subtract(brave).dropna()
opera_speedup = opera.subtract(brave).dropna()

fig, (ax_plt, ax_flt) = plt.subplots(1, 2, sharey=True)
# fig.suptitle('Windows Performance', fontsize=24)
fig.set_size_inches(11, 5)

ax_plt.set_ylabel('CDF (0-1)')
ax_plt.set_xlabel('Time Saved (sec)')
ax_plt.title.set_text('Brave\'s PLT Speedup')
curve = cdfplot_new(chrome_speedup['loadEvent.median'] / 1000, ax_plt)
plt.setp(curve, linewidth = 2, color = bar_colors[1], linestyle = style[0], label = 'Chrome')
curve = cdfplot_new(firefox_speedup['loadEvent.median'] / 1000, ax_plt)
plt.setp(curve, linewidth = 2, color = bar_colors[3], linestyle = style[0], label = 'Firefox')
curve = cdfplot_new(opera_speedup['loadEvent.median'] / 1000, ax_plt)
plt.setp(curve, linewidth = 2, color = bar_colors[2], linestyle = style[0], label = 'Opera')
plt.legend(loc = 'lower right')

ax_flt.set_xlabel('Time Saved (sec)')
ax_flt.title.set_text('Brave\'s FLT Speedup')
curve = cdfplot_new(chrome_speedup['fullyLoaded.median'] / 1000, ax_flt)
plt.setp(curve, linewidth = 2, color = bar_colors[1], linestyle = style[0], label = 'Chrome')
curve = cdfplot_new(firefox_speedup['fullyLoaded.median'] / 1000, ax_flt)
plt.setp(curve, linewidth = 2, color = bar_colors[3], linestyle = style[0], label = 'Firefox')
curve = cdfplot_new(opera_speedup['fullyLoaded.median'] / 1000, ax_flt)
plt.setp(curve, linewidth = 2, color = bar_colors[2], linestyle = style[0], label = 'Opera')
plt.legend(loc = 'lower right')

plt.savefig('perf_macos_cdf.png')

firefox_speedup['fullyLoaded.median'].describe()
firefox_speedup['loadEvent.median'].describe()
