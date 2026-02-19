import numpy as np
import matplotlib.pyplot as plt

# ── Raw data (5 runs each) ──────────────────────────────────────────────

data = {
    "Linux": {
        "regular": {
            "cycles": [69136345549427, 37558142268745, 61251969210134, 71506306057769, 69139669739100],
            "dtlb_load": [23625876016589, 12972407727452, 20824558365748, 24466792202751, 23623130346529],
        },
        "interleave": {
            "cycles": [61571408296336, 61514915919486, 61491171446763, 61567290678452, 61537184243686],
            "dtlb_load": [19619344951250, 19585723949233, 19605373276065, 19651147411309, 19614412100263],
        },
    },
    "Mitosis": {
        "regular": {
            "cycles": [50448582032229, 50586568700023, 50797471137411, 50863578832932, 50450275894702],
            "dtlb_load": [10217718962262, 10222869306452, 10245605353475, 10254062124398, 10213052964534],
        },
        "interleave": {
            "cycles": [47341602306418, 47309687511281, 47323012157189, 47346614008023, 47325445855561],
            "dtlb_load": [9949114793980, 9939471988276, 9944805316760, 9957285472346, 9956188151409],
        },
    },
    "Hydra": {
        "regular": {
            "cycles": [50465417190420, 50464898674059, 50444531179315, 49978917131834, 50096445756987],
            "dtlb_load": [10105552174563, 10100289515256, 10099734393129, 10083632533144, 10068178688806],
        },
        "interleave": {
            "cycles": [46935360545262, 46948699086672, 46967676812859, 46912299721212, 46906302214184],
            "dtlb_load": [9874719637927, 9879675281675, 9883910215817, 9872511807581, 9876010841116],
        },
    },
    "WASP": {
        "regular": {
            "cycles": [51172984432468, 45517046961802, 51429664460730, 51842410412962, 51699904549310],
            "dtlb_load": [10596182521121, 9168194091218, 10625616099354, 10607745830577, 10551656147857],
        },
        "interleave": {
            "cycles": [46610772215823, 46399435207146, 46601045362411, 46583578862974, 46610396585725],
            "dtlb_load": [10000916657970, 9913501871817, 9989104910294, 9979203038894, 9996103993556],
        },
    },
}

systems = list(data.keys())

# ── Convert MRS from kilobytes to gigabytes ─────────────────────────────

mrs_kb = 97438208
mrs_gb = mrs_kb / 1024 / 1024  # ≈ 92.9 GB

# ── Compute means, normalize to Linux ───────────────────────────────────

means = {}
for s in systems:
    means[s] = {}
    for v in ("regular", "interleave"):
        walks  = np.array(data[s][v]["dtlb_load"])
        cycles = np.array(data[s][v]["cycles"])
        other  = cycles - walks
        means[s][v] = {"walk": np.mean(walks), "other": np.mean(other), "total": np.mean(cycles)}

norm = {}
for s in systems:
    norm[s] = {}
    for v in ("regular", "interleave"):
        base = means["Linux"][v]["total"]
        total_n = means[s][v]["total"] / base
        fw = means[s][v]["walk"]  / means[s][v]["total"]
        fo = means[s][v]["other"] / means[s][v]["total"]
        norm[s][v] = {"walk": total_n * fw, "other": total_n * fo, "total": total_n}

# ── Plot ────────────────────────────────────────────────────────────────

fig, axes = plt.subplots(1, 2, figsize=(14, 6), sharey=True)

c_walk  = "#C0392B"
c_other = "#2C3E50"
width   = 0.52

variant_titles = {"regular": "Regular", "interleave": "Interleave"}

for ax, v in zip(axes, ("regular", "interleave")):
    x = np.arange(len(systems))

    others = [norm[s][v]["other"] for s in systems]
    walks  = [norm[s][v]["walk"]  for s in systems]
    totals = [norm[s][v]["total"] for s in systems]

    ax.bar(x, others, width, label="Compute", color=c_other, edgecolor="white", linewidth=0.5)
    ax.bar(x, walks, width, bottom=others, label="Page Table Walks", color=c_walk, edgecolor="white", linewidth=0.5)

    # Walk % inside red portion
    for j, (w, o, t) in enumerate(zip(walks, others, totals)):
        pct = w / t * 100
        ax.text(x[j], o + w / 2, f"{pct:.0f}%", ha="center", va="center",
                fontsize=10, fontweight="bold", color="white")

    # Total label on top
    for j, t in enumerate(totals):
        ax.text(x[j], t + 0.015, f"{t:.2f}", ha="center", va="bottom",
                fontsize=9.5, fontweight="bold")

    ax.set_title(variant_titles[v], fontsize=13, fontweight="bold")
    ax.set_xticks(x)
    ax.set_xticklabels(systems, fontsize=11, fontweight="bold")
    ax.axhline(1.0, color="gray", linestyle="--", linewidth=0.8, alpha=0.6)
    ax.grid(axis="y", alpha=0.2)
    ax.set_axisbelow(True)
    ax.legend(fontsize=10, loc="lower left")

axes[0].set_ylabel("Normalized Cycles (Linux = 1.0)", fontsize=11)
axes[1].set_ylim(0, 1.1)

fig.suptitle(f"BTree MRS {mrs_gb:.1f} GB (Intel 4 Socket, n=5) — Cycles Breakdown\n"
             "(each panel normalized to its own Linux baseline)",
             fontsize=14, fontweight="bold")
plt.tight_layout()
plt.savefig("btree_normalized_breakdown.png", dpi=200, bbox_inches="tight")
plt.show()
print("Saved to btree_normalized_breakdown.png")
