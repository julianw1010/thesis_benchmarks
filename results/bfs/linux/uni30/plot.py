import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #310: numactl-wasp — all on Node 1: 1+3+3+5=12
e310 = [0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #311: bench_bfs_mt (PGD+PUD+PMD+PTE per node)
e311 = [
    1+4+142+70022,   # Node0  = 70169
    0+0+4+482,       # Node1  = 486
    0+0+3+479,       # Node2  = 482
    0+0+6+496,       # Node3  = 502
    0+0+8+462,       # Node4  = 470
    0+0+10+505,      # Node5  = 515
    0+0+8+476,       # Node6  = 484
    0+0+10+484,      # Node7  = 494
    0+0+8+482,       # Node8  = 490
    0+0+8+485,       # Node9  = 493
    0+0+8+477,       # Node10 = 485
    0+0+9+476,       # Node11 = 485
    0+0+8+493,       # Node12 = 501
    0+0+8+489,       # Node13 = 497
    0+0+8+494,       # Node14 = 502
    0+0+5+485,       # Node15 = 490
]

# Entry #312: time — all on Node 1: 1+3+3+5=12
e312 = [0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e310) + np.array(e311) + np.array(e312)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(bfs uni30 / bench_bfs_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_bfs_uni30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_bfs_uni30.png")
