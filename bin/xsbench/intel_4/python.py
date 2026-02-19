import numpy as np
import matplotlib.pyplot as plt

# ── Raw data (5 runs each) ──────────────────────────────────────────────

data = {
    "Linux": {
        "regular": {
            "cycles": [51146986947699, 51431828827808, 51562944198698, 51040592554932, 51455275864496],
            "dtlb_load": [16115614465394, 16177054747649, 16209243354809, 16109168442086, 16202181442516],
        },
        "interleave": {
            "cycles": [25364049765443, 25371498482326, 25354634734999, 25367474354440, 25385555449218],
            "dtlb_load": [8314503428308, 8317533343924, 8315584947465, 8313292431564, 8320950635166],
        },
    },
    "Mitosis": {
        "regular": {
            "cycles": [39415155221772, 39140184633938, 46550989897410, 39304812398920, 39345686821900],
            "dtlb_load": [4869471563933, 4858560171906, 5177630756036, 4866036939427, 4873455549734],
        },
        "interleave": {
            "cycles": [20059815465034, 20087399385796, 20091059394696, 20088316022319, 20104993822431],
            "dtlb_load": [3892829224624, 3901982080419, 3900308279484, 3900547832525, 3900725264683],
        },
    },
    "Hydra": {
        "regular": {
            "cycles": [39210909035183, 44810901289698, 45181690180960, 39289759660122, 39043909294230],
            "dtlb_load": [4752249783567, 4965959379224, 4976689709105, 4764049540565, 4761657167706],
        },
        "interleave": {
            "cycles": [20005068905590, 20016323816575, 20044700287719, 20009079128166, 19997458134748],
            "dtlb_load": [3884821863024, 3891157962009, 3898315432207, 3893929316414, 3890782820565],
        },
    },
    "WASP": {
        "regular": {
            "cycles": [45228685958973, 45360569919683, 44841975574859, 27466785647897, 39194067222631],
            "dtlb_load": [5270380994144, 5208774078580, 5148944363445, 3141079918645, 4975461243489],
        },
        "interleave": {
            "cycles": [20017086049172, 20013099568514, 20004474394778, 20014430910936, 19995494143891],
            "dtlb_load": [3994902459190, 3992615061062, 3998032028217, 3997899819186, 3979206056770],
        },
    },
}

systems = list(data.keys())

# ── Convert MRS from kilobytes to gigabytes ─────────────────────────────

mrs_kb = 102898292
mrs_gb = mrs_kb / 1024 / 1024  # ≈ 98.13 GB

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

fig.suptitle(f"XSBench MRS {mrs_gb:.1f} GB (Intel 4 Socket, n=5) — Cycles Breakdown\n"
             "(each panel normalized to its own Linux baseline)",
             fontsize=14, fontweight="bold")
plt.tight_layout()
plt.savefig("xsbench_normalized_breakdown.png", dpi=200, bbox_inches="tight")
plt.show()
print("Saved to xsbench_normalized_breakdown.png")
