import matplotlib.pyplot as plt
import numpy as np

nodes = [f"Node {i}" for i in range(16)]

# Total primary pages per node (sum of PGD+PUD+PMD+PTE across all 3 entries)
# Entry #352: Node1=1+3+3+6=13, rest=0
# Entry #353: Node0=1+3+145+69421=69570, Node1=10+828=838, Node2=9+839=848, ...
# Entry #354: Node1=1+3+3+5=12, rest=0

e352 = [0, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
e353 = [
    1+3+145+69421,  # Node0 = 69570
    0+0+10+828,     # Node1 = 838
    0+0+9+839,      # Node2 = 848
    0+0+12+834,     # Node3 = 846
    0+0+9+834,      # Node4 = 843
    0+0+9+844,      # Node5 = 853
    0+0+12+839,     # Node6 = 851
    0+0+9+836,      # Node7 = 845
    0+0+10+844,     # Node8 = 854
    0+0+10+830,     # Node9 = 840
    0+0+10+850,     # Node10 = 860
    0+0+9+839,      # Node11 = 848
    0+0+11+842,     # Node12 = 853
    0+0+9+836,      # Node13 = 845
    0+0+3+845,      # Node14 = 848
    0+0+6+845,      # Node15 = 851
]
e354 = [0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

totals = np.array(e352) + np.array(e353) + np.array(e354)

fig, ax = plt.subplots(figsize=(14, 6))
bars = ax.bar(nodes, totals, color="#2c7fb8", edgecolor="white", linewidth=0.5)

# Annotate each bar
for bar, val in zip(bars, totals):
    ax.annotate(f"{val:,}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                textcoords="offset points", xytext=(0, 5), ha="center", fontsize=9)

ax.set_ylabel("Total Primary Page Table Pages")
ax.set_xlabel("NUMA Node")
ax.set_title("Mitosis Page Table Distribution — Total Primary Pages per NUMA Node\n(summed across all history entries and PT levels)")
ax.set_yscale("log")
ax.set_ylim(1, 200000)
ax.grid(axis="y", alpha=0.3)
fig.tight_layout()
plt.savefig("pt_distribution.png", dpi=150)
plt.show()
print("Saved to pt_distribution.png")
