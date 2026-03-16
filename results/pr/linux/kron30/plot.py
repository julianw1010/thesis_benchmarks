import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #19: numactl-wasp — all on Node 0: 1+3+3+5=12
e19 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #20: bench_pr_mt (PGD+PUD+PMD+PTE per node)
e20 = [
    0+1+137+69413,   # Node0  = 69551
    1+2+7+520,       # Node1  = 530
    0+0+3+512,       # Node2  = 515
    0+0+8+512,       # Node3  = 520
    0+0+10+512,      # Node4  = 522
    0+0+10+512,      # Node5  = 522
    0+0+9+512,       # Node6  = 521
    0+0+10+512,      # Node7  = 522
    0+0+8+512,       # Node8  = 520
    0+0+9+512,       # Node9  = 521
    0+0+8+512,       # Node10 = 520
    0+0+8+512,       # Node11 = 520
    0+0+10+512,      # Node12 = 522
    0+0+10+512,      # Node13 = 522
    0+0+8+512,       # Node14 = 520
    0+0+4+514,       # Node15 = 518
]

# Entry #21: time — all on Node 0: 1+3+3+6=13
e21 = [13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e19) + np.array(e20) + np.array(e21)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(pr kron30 / bench_pr_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_pr_kron30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_pr_kron30.png")
