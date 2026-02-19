import numpy as np
import matplotlib.pyplot as plt

# ── Raw data (5 runs each) ──────────────────────────────────────────────

data = {
    "Linux": {
        "regular": {
            "cycles": [31077576288622, 17080995883654, 31038655920751, 33288568662433, 30199072434710],
            "dtlb_load": [11274039272658, 6189303312916, 11280429852582, 12282812510184, 10980339526511],
        },
        "interleave": {
            "cycles": [28186019737856, 28302585721277, 28319298272858, 28290690665573, 28283350746708],
            "dtlb_load": [10209457816659, 10254965962989, 10269144015311, 10255229291465, 10253310836133],
        },
    },
    "Mitosis": {
        "regular": {
            "cycles": [20498820432494, 19604379709964, 22044966757215, 22066939504252, 22117559984119],
            "dtlb_load": [4647782633221, 4601807331626, 5101980116616, 5103681236199, 5109724138193],
        },
        "interleave": {
            "cycles": [19948260081633, 19966489980717, 19950411173743, 19939234013865, 19968957857114],
            "dtlb_load": [5122565451774, 5129351833318, 5125483193480, 5126148967167, 5127588816479],
        },
    },
    "Hydra": {
        "regular": {
            "cycles": [21718071991650, 22444434469698, 22426626277491, 22423140668458, 22419186512720],
            "dtlb_load": [5204409357683, 5226270687076, 5233562000064, 5237738831517, 5225301482274],
        },
        "interleave": {
            "cycles": [20189663346350, 20263044680231, 20230872302988, 20267089351474, 20190280137707],
            "dtlb_load": [5170985758043, 5196769897404, 5184498470954, 5199951198410, 5180317934728],
        },
    },
    "WASP": {
        "regular": {
            "cycles": [22166878236100, 22191993842645, 22255167697193, 22031535456008, 22400669807148],
            "dtlb_load": [5341655771425, 5258627808820, 5341193618236, 5315390028605, 5355798893756],
        },
        "interleave": {
            "cycles": [20305899548511, 20108102661242, 20299866436708, 20158875927831, 20349259547764],
            "dtlb_load": [5274155207981, 5177855265227, 5282911871103, 5208646177524, 5295904578396],
        },
    },
}

systems = list(data.keys())

# ── Convert MRS from kilobytes to gigabytes ─────────────────────────────

mrs_kb = 87066112
mrs_gb = mrs_kb / 1024 / 1024  # ≈ 83.0 GB

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

fig.suptitle(f"Canneal MRS {mrs_gb:.1f} GB (Intel 4 Socket, n=5) — Cycles Breakdown\n"
             "(each panel normalized to its own Linux baseline)",
             fontsize=14, fontweight="bold")
plt.tight_layout()
plt.savefig("canneal_normalized_breakdown.png", dpi=200, bbox_inches="tight")
plt.show()
print("Saved to canneal_normalized_breakdown.png")
