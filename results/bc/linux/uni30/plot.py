import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #376: numactl-wasp — all on Node 0: 1+3+3+5=12
e376 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #377: bench_bc_mt
e377 = [
    0+0+139+70015,   # Node0  = 70154
    1+3+11+940,      # Node1  = 955
    0+1+11+923,      # Node2  = 935
    0+0+10+918,      # Node3  = 928
    0+0+9+918,       # Node4  = 927
    0+0+9+924,       # Node5  = 933
    0+0+11+923,      # Node6  = 934
    0+0+11+916,      # Node7  = 927
    0+0+9+910,       # Node8  = 919
    0+0+10+903,      # Node9  = 913
    0+0+9+898,       # Node10 = 907
    0+0+9+925,       # Node11 = 934
    0+0+10+918,      # Node12 = 928
    0+0+10+914,      # Node13 = 924
    0+0+10+903,      # Node14 = 913
    0+0+4+925,       # Node15 = 929
]

# Entry #378: time — all on Node 0: 1+3+3+5=12
e378 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e376) + np.array(e377) + np.array(e378)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(uni30 / bench_bc_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_uni30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_uni30.png")
