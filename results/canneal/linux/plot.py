import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Entry #462: numactl-wasp — all on Node 0: 1+3+3+5=12
e462 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Entry #463: bench_canneal_mt (PGD+PUD+PMD+PTE per node)
e463 = [
    0+1+131+67750,   # Node0  = 67882
    1+2+8+2187,      # Node1  = 2198
    0+0+5+2184,      # Node2  = 2189
    0+0+5+2184,      # Node3  = 2189
    0+0+3+2184,      # Node4  = 2187
    0+0+7+2184,      # Node5  = 2191
    0+0+5+2184,      # Node6  = 2189
    0+0+4+2184,      # Node7  = 2188
    0+0+11+2184,     # Node8  = 2195
    0+0+4+2184,      # Node9  = 2188
    0+0+6+2184,      # Node10 = 2190
    0+0+4+2184,      # Node11 = 2188
    0+0+6+2184,      # Node12 = 2190
    0+0+4+2184,      # Node13 = 2188
    0+0+3+2184,      # Node14 = 2187
    0+0+8+2184,      # Node15 = 2192
]

# Entry #464: time — all on Node 0: 1+3+3+5=12
e464 = [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e462) + np.array(e463) + np.array(e464)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

for bar, val in zip(bars, totals):
    if val > 0:
        ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(canneal / bench_canneal_mt, summed across all entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution_canneal.png", dpi=150)
plt.show()
print("Saved to pt_distribution_canneal.png")
