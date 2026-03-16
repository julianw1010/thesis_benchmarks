import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #412: numactl-wasp — all on Node 8: 1+3+3+5=12
e412 = [0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0]

# Entry #413: bench_xsbench_mt (PGD+PUD+PMD+PTE per node)
e413 = [
    0+1+199+100620,  # Node0  = 100820
    0+0+2+8,         # Node1  = 10
    0+0+1+8,         # Node2  = 9
    0+0+0+8,         # Node3  = 8
    0+0+2+8,         # Node4  = 10
    0+0+1+8,         # Node5  = 9
    0+0+2+8,         # Node6  = 10
    0+0+2+8,         # Node7  = 10
    0+0+2+8,         # Node8  = 10
    1+2+5+11,        # Node9  = 19
    0+0+3+8,         # Node10 = 11
    0+0+0+8,         # Node11 = 8
    0+0+0+8,         # Node12 = 8
    0+0+1+8,         # Node13 = 9
    0+0+4+8,         # Node14 = 12
    0+0+4+8,         # Node15 = 12
]

# Entry #414: time — all on Node 8: 1+3+3+5=12
e414 = [0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e412) + np.array(e413) + np.array(e414)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(xsbench / bench_xsbench_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 300000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_xsbench.png", dpi=150)
plt.show()
print("Saved to pt_distribution_xsbench.png")
