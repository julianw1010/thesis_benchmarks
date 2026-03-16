import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #507: numactl-wasp — all on Node 10: 1+3+3+5=12
e507 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0]

# Entry #508: bench_btree_mt (PGD+PUD+PMD+PTE per node)
e508 = [
    0+1+187+95282,   # Node0  = 95470
    0+0+0+0,         # Node1  = 0
    0+0+0+0,         # Node2  = 0
    0+0+0+0,         # Node3  = 0
    0+0+0+0,         # Node4  = 0
    0+0+0+0,         # Node5  = 0
    0+0+0+0,         # Node6  = 0
    0+0+0+0,         # Node7  = 0
    0+0+0+0,         # Node8  = 0
    0+0+0+0,         # Node9  = 0
    0+0+0+0,         # Node10 = 0
    1+2+2+3,         # Node11 = 8
    0+0+0+0,         # Node12 = 0
    0+0+0+0,         # Node13 = 0
    0+0+0+0,         # Node14 = 0
    0+0+0+0,         # Node15 = 0
]

# Entry #509: time — all on Node 10: 1+3+3+5=12
e509 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0]

totals = np.array(e507) + np.array(e508) + np.array(e509)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(btree / bench_btree_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 300000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_btree.png", dpi=150)
plt.show()
print("Saved to pt_distribution_btree.png")
