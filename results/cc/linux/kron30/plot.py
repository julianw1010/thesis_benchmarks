import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #220: numactl-wasp — all on Node 0: 1+3+3+5=12
e220 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #221: bench_cc_mt (PGD+PUD+PMD+PTE per node)
e221 = [
    0+0+137+69413,   # Node0  = 69550
    1+3+6+392,       # Node1  = 402
    0+0+7+384,       # Node2  = 391
    0+0+7+384,       # Node3  = 391
    0+0+7+384,       # Node4  = 391
    0+0+4+384,       # Node5  = 388
    0+0+7+384,       # Node6  = 391
    0+0+6+384,       # Node7  = 390
    0+0+8+384,       # Node8  = 392
    0+0+8+384,       # Node9  = 392
    0+0+8+384,       # Node10 = 392
    0+0+8+384,       # Node11 = 392
    0+0+8+384,       # Node12 = 392
    0+0+8+384,       # Node13 = 392
    0+0+8+384,       # Node14 = 392
    0+0+5+385,       # Node15 = 390
]

# Entry #222: time — all on Node 0: 1+3+3+5=12
e222 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e220) + np.array(e221) + np.array(e222)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(cc kron30 / bench_cc_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_cc_kron30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_cc_kron30.png")
