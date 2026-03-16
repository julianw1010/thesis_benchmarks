import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #112: numactl-wasp — all on Node 0: 1+3+3+6=13
e112 = [13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #113: bench_pr_spmv_mt (PGD+PUD+PMD+PTE per node)
e113 = [
    0+0+138+70015,   # Node0  = 70153
    1+3+8+519,       # Node1  = 531
    0+0+8+512,       # Node2  = 520
    0+0+10+512,      # Node3  = 522
    0+0+9+512,       # Node4  = 521
    0+0+8+512,       # Node5  = 520
    0+0+10+512,      # Node6  = 522
    0+0+11+512,      # Node7  = 523
    0+0+8+512,       # Node8  = 520
    0+0+9+512,       # Node9  = 521
    0+0+8+512,       # Node10 = 520
    0+0+11+512,      # Node11 = 523
    0+0+9+512,       # Node12 = 521
    0+0+9+512,       # Node13 = 521
    0+0+8+512,       # Node14 = 520
    0+0+3+514,       # Node15 = 517
]

# Entry #114: time — all on Node 0: 1+3+3+5=12
e114 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e112) + np.array(e113) + np.array(e114)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(pr_spmv uni30 / bench_pr_spmv_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_pr_spmv_uni30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_pr_spmv_uni30.png")
