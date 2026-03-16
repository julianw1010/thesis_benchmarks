import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #286: numactl-wasp — all on Node 0: 1+3+3+5=12
e286 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #287: bench_bfs_mt (PGD+PUD+PMD+PTE per node)
e287 = [
    0+1+136+69413,   # Node0  = 69550
    1+3+8+424,       # Node1  = 436
    0+0+6+422,       # Node2  = 428
    0+0+7+427,       # Node3  = 434
    0+0+8+420,       # Node4  = 428
    0+0+8+421,       # Node5  = 429
    0+0+8+419,       # Node6  = 427
    0+0+9+426,       # Node7  = 435
    0+0+8+407,       # Node8  = 415
    0+0+8+410,       # Node9  = 418
    0+0+8+413,       # Node10 = 421
    0+0+8+413,       # Node11 = 421
    0+0+8+417,       # Node12 = 425
    0+0+8+412,       # Node13 = 420
    0+0+8+408,       # Node14 = 416
    0+0+6+413,       # Node15 = 419
]

# Entry #288: time — all on Node 0: 1+3+3+5=12
e288 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e286) + np.array(e287) + np.array(e288)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(bfs kron30 / bench_bfs_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_bfs_kron30.png", dpi=150)
plt.show()
print("Saved to pt_distribution_bfs_kron30.png")
