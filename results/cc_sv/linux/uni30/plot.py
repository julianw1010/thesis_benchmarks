import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #178: numactl-wasp — all on Node 0: 1+3+3+5=12
e178 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #179: bench_cc_sv_mt (PGD+PUD+PMD+PTE per node)
e179 = [
    0+0+138+70015,   # Node0  = 70153
    1+3+4+391,       # Node1  = 399
    0+0+1+384,       # Node2  = 385
    0+0+2+384,       # Node3  = 386
    0+0+2+384,       # Node4  = 386
    0+0+0+384,       # Node5  = 384
    0+0+8+384,       # Node6  = 392
    0+0+8+384,       # Node7  = 392
    0+0+8+384,       # Node8  = 392
    0+0+8+384,       # Node9  = 392
    0+0+8+384,       # Node10 = 392
    0+0+8+384,       # Node11 = 392
    0+0+8+384,       # Node12 = 392
    0+0+8+384,       # Node13 = 392
    0+0+8+384,       # Node14 = 392
    0+0+6+385,       # Node15 = 391
]

# Entry #180: time — all on Node 0: 1+3+3+6=13
e180 = [13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e178) + np.array(e179) + np.array(e180)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(cc_sv uni30 / bench_cc_sv_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_cc_sv_uni30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_cc_sv_uni30.png")
