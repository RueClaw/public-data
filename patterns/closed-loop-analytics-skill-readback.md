# Closed-Loop Analytics Skill Readback

**Source:** ericosiu/ai-marketing-skills  
**Repo:** https://github.com/ericosiu/ai-marketing-skills  
**License:** MIT  
**Reviewed:** 2026-07-17  

## Pattern

Do not treat an agent skill, prompt, rubric, or playbook change as improved until outcome data proves it. After a change ships, run a readback against the relevant platform metrics and decide whether to promote, keep testing, roll back, or mark the change unproven.

## Core Loop

1. Record the change: what changed, why, owner, target workflow, and expected primary metric.
2. Define the comparison: baseline window, candidate window, source systems, primary metric, secondary metrics, and known confounders.
3. Pull actual outcomes after the change window.
4. Compare baseline vs candidate.
5. Decide: promote, keep testing, rollback, or unproven.
6. Patch the skill/playbook only when evidence clears the promotion rule.
7. Schedule the next readback when the result is inconclusive or needs longer-term validation.

## Readback Fields

Every promoted change should carry:

- change made
- owner
- baseline window
- candidate window
- source systems pulled
- primary metric
- secondary metrics
- metric winner
- caveats and confounders
- decision
- next patch
- next readback date

## Promotion Rules

Promote when the candidate beats baseline on the primary metric, or when it exposes a repeatable audience/customer/system signal, and downside metrics are not meaningfully worse.

Do not promote when volume is too low, attribution is dirty, connector data failed, seasonality explains the result, or the only positive signal is that the author liked the output.

## Why It Works

Agent skills often improve locally and regress in production. A generated answer can look better to the author while hurting the real business or user metric. The readback loop forces the skill to earn durable status from observed outcomes.

This applies outside marketing:

- coding skills: compare bug rate, review comments, rollback rate, or CI failures
- research skills: compare correction rate, citation quality, and stale-claim rate
- support skills: compare resolution, escalation, handle time, and satisfaction
- content skills: compare engagement, conversion, editorial corrections, and rejection rate

## Caveats

Keep external writes approval-gated. Pulling analytics is usually safe; publishing content, changing budgets, mutating CRM records, sending email, or editing production systems should require explicit authorization.

---

**Attribution:** Based on `closed-loop-analytics-upgrade/SKILL.md` from ericosiu/ai-marketing-skills, MIT License.
