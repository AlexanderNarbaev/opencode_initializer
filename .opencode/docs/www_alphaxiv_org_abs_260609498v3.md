# Self-Harness: Harnesses That Improve Themselves | alphaXiv

> Source: https://www.alphaxiv.org/abs/2606.09498v3
> Cached: 2026-08-21T18:00:21.595Z

---

Submitted 20 Aug 2026

en# Self-Harness: Harnesses That Improve Themselves

HZHangfan ZhangSZShao ZhangKLKangcong LiCZChen Zhang[Yang Chen](/@yang-chen)[Yiqun Zhang](/@yiqun-zhang)[Lei Bai](/@lei-bai)[Shuyue Hu](/@shuyue-hu)## Abstract

The performance of LLM-based agents is jointly shaped by their base models and the harnesses that mediate their interaction with the environment. Because different models exhibit distinct behaviors, effective harness design is inherently model-specific. Yet agent harnesses are still largely engineered by human experts, a paradigm that scales poorly as modern LLMs become increasingly diverse and rapidly evolving. In this paper, we introduce Self-Harness, a new paradigm in which an LLM-based agent improves its own operating harness, without relying on human engineers or stronger external agents. We operationalize Self-Harness as an iterative loop with three stages: Weakness Mining, which identifies model-specific failure patterns from execution traces; Harness Proposal, which generates diverse yet minimal harness modifications tied to these failures; and Proposal Validation, which accepts candidate edits only after regression testing. We instantiate Self-Harness across Terminal-Bench-2.0, SWE-bench Verified, and AppWorld using a minimal initial harness and three base models from diverse families: MiniMax M2.5, Qwen3.5-35B-A3B, and GLM-5. Across all nine model--benchmark combinations, every final harness improves both held-in and held-out pass rates, with overall relative gains of up to 132%. Qualitative analyses further show that the retained mechanisms address benchmark-specific bottlenecks in artifact handling and runtime control, software-patch verification, and application-state retrieval. These results suggest a path toward LLM-based agents that are not merely shaped by their harnesses, but can also participate in reshaping them.

View more[View Paper](/pdf/2606.09498v3)394[3](#discussion)Save

Cite## AI Overview

## The Paradigm of Self-Improving Agent Harnesses

Large language model (LLM) agents do not operate in a vacuum. Their ability to solve complex tasks—like fixing software bugs or managing files via a terminal—depends heavily on the "harness" that surrounds the core model. A harness is the structural framework that defines how an agent interacts with its environment; it includes the system prompts that guide behavior, the tools available for use, the logic for error recovery, and the verification steps taken before finalizing a result.

*Figure 1: Comparison between traditional human harness engineering, external meta-harness optimization, and the Self-Harness approach where the agent improves itself.*
Traditionally, these harnesses have been hand-crafted by human experts. However, as the number of available LLMs grows and their individual behaviors diverge, manual engineering becomes a bottleneck. A harness optimized for one model might fail for another due to differences in how each model handles specific tool errors or interprets prompts.

Self-Harness introduces an internal, iterative loop where a fixed language model MMM identifies its own operational failures and proposes modifications to its own harness hhh. By automating the refinement of the system prompts, tools, and orchestration logic, the agent becomes "self-creating." This approach reduces the need for constant human intervention and allows the system to adapt to the specific behavioral quirks of the underlying model without changing the model&#x27;s parameters.

## The Components of an Agentic System

To understand how Self-Harness works, it is first necessary to define the agentic system. An agent is a composition of a language model MMM and a harness hhh. When given a task from a dataset DDD, the agent generates an execution trace τ\tauτ, which is a sequence of thoughts, tool calls, and environment responses. The final outcome yyy is then assessed by an evaluator EEE to determine if the task was successful.

The harness hhh serves as the "operating system" for the agent. It dictates the lifecycle of a task, from the initial "bootstrap" instructions to the final verification of the result. Because MMM remains fixed, the only way to improve the agent&#x27;s performance is to modify hhh. Self-Harness treats the harness as a collection of editable surfaces—specific configuration points that the model can rewrite to improve its future performance.

## The Three-Stage Iterative Loop

The Self-Harness framework operates through a structured cycle composed of three distinct stages: Weakness Mining, Harness Proposal, and Proposal Validation.

### Weakness Mining: Finding Patterns in Failure

The first stage involves identifying why the agent is failing. Instead of looking at failures in isolation, the system performs "Weakness Mining." The agent runs on a held-in dataset DinD_{\text{in}}Din​, and the failed execution traces FtF_tFt​ are collected.

These failures are then clustered based on a "failure signature" ϕ(ri)\phi(r_i)ϕ(ri​). A signature is composed of:

- The terminal cause cic_ici​ (e.g., a timeout or a missing file).

- The behavioral status qiq_iqi​ (whether the agent made a mistake or the environment was the issue).

- The reusable mechanism mim_imi​ (the specific part of the harness involved in the failure).

By grouping failures that share the same underlying mechanism, the system identifies recurrent patterns. These patterns are bundled into an "evidence bundle" BtB_tBt​, which provides the model with concrete data on where its current harness is falling short.

### Harness Proposal: The Model as its Own Architect

Once the weaknesses are identified, the same fixed language model MMM, acting as a "proposer," generates candidate edits to the harness. The proposer is given the current harness hth_tht​ and the evidence bundle BtB_tBt​.

The goal is to generate KKK distinct proposal bundles PtP_tPt​. Each bundle contains a specific edit Δj\Delta_jΔj​ and an audit record aja_jaj​ explaining the reasoning. A key requirement is that the edits must be minimal. Rather than rewriting the entire system, the model is encouraged to make targeted changes to specific configurable surfaces, such as adding a failure-recovery instruction or refining a tool definition.

The relationship between the old and new harness can be represented as:

ht(j)=f(ht,Δj)h^{(j)}_t = f(h_t, \Delta_j)ht(j)​=f(ht​,Δj​)
where fff is a function that applies the proposed modification Δj\Delta_jΔj​ to the existing harness hth_tht​.

### Proposal Validation: The Regression Gate

Not all proposed edits are improvements. To ensure that a change actually helps, every candidate harness ht(j)h^{(j)}_tht(j)​ undergoes rigorous validation. This involves testing the candidate on both the held-in split DinD_{\text{in}}Din​ (to see if the specific failure was fixed) and a held-out split DhoD_{\text{ho}}Dho​ (to ensure no new problems were introduced).

The system calculates the change in performance on both splits:

Δin(j)=Pin(ht(j))−Pin(ht)≥0\Delta^{(j)}_{\text{in}} = P_{\text{in}}(h^{(j)}_t) - P_{\text{in}}(h_t) \geq 0Δin(j)​=Pin​(ht(j)​)−Pin​(ht​)≥0
Δho(j)=Pho(ht(j))−Pho(ht)≥0\Delta^{(j)}_{\text{ho}} = P_{\text{ho}}(h^{(j)}_t) - P_{\text{ho}}(h_t) \geq 0Δho(j)​=Pho​(ht(j)​)−Pho​(ht​)≥0
A proposal is only accepted if it improves performance on at least one split without causing a regression on the other. This conservative gate ensures that the harness evolution is stable and statistically grounded. If multiple independent edits pass this gate, they are merged to form the next generation harness ht+1h_{t+1}ht+1​.

## Experimental Results Across Benchmarks

The Self-Harness approach was tested using three diverse models—MiniMax M2.5, Qwen3.5-35B-A3B, and GLM-5—across three challenging benchmarks: Terminal-Bench-2.0, SWE-bench Verified, and AppWorld.

### Performance Gains

Across all combinations, the final harnesses produced significant improvements. On **Terminal-Bench-2.0**, Qwen3.5 saw its pass rate jump from 18.0%18.0\%18.0% to 36.7%36.7\%36.7%, a relative increase of 104%104\%104%. MiniMax M2.5 improved from 42.2%42.2\%42.2% to 53.9%53.9\%53.9%.

On **SWE-bench Verified**, which requires agents to fix real-world software issues in large repositories, the gains were equally notable. Qwen3.5 improved its performance by 113%113\%113% (from 19.5%19.5\%19.5% to 41.5%41.5\%41.5%). Even the strongest baseline, GLM-5, managed to improve from 52.0%52.0\%52.0% to 55.5%55.5\%55.5%.

**AppWorld**, a benchmark requiring multi-step interaction with various APIs (like Spotify and Venmo), saw the most dramatic absolute gains. GLM-5&#x27;s pass rate rose from 44.4%44.4\%44.4% to 85.0%85.0\%85.0%, a relative increase of 91%91\%91%.

### Generalization to Unseen Tasks

A critical finding was that the improvements generalized to the held-out splits. For example, MiniMax M2.5&#x27;s performance on the held-out tasks of Terminal-Bench improved by 53%53\%53%. This confirms that the model was not just "memorizing" how to solve specific tasks in the training set, but was actually improving the underlying logic of its interaction harness.

## Model-Specific Evolution: A Qualitative Look

The qualitative analysis of the retained edits revealed that each model "learned" to fix the specific issues it struggled with.

- **MiniMax M2.5** focused on artifact management. Its evolved harness included instructions to create output files as early as possible and to use correct content tags for structured tool outputs.

- **Qwen3.5** struggled with recovery loops. Its edits introduced "loop breakers"—instructions that prevented the agent from repeating the same failed command and forced it to try a different approach after a few failed attempts.

- **GLM-5** optimized its environment handling. It added mechanisms to ensure that environment variables and paths remained persistent across different shell sessions.

*Figure 2: Examples of harness edits proposed and retained by MiniMax M2.5 to address specific tool-use and recovery failures.*
In some cases, the models even introduced structural changes, such as spawning "subagents" to handle specific sub-tasks. For example, on SWE-bench, Qwen3.5 delegated the final check of a code patch to a specialized `patch_verifier` subagent, which analyzed the `git diff` before submission.

## Significance of the Self-Harness Paradigm

The success of Self-Harness demonstrates that the performance of an AI agent is not set in stone by the weights of its language model. By allowing the model to analyze its own behavior and tune its operating environment, we can achieve substantial performance gains without the high cost of model retraining or fine-tuning.

This work highlights several key principles for the future of agent engineering:

- **Model-Specific Optimization:** A one-size-fits-all harness is suboptimal. Harnesses should be tailored to the specific behavioral profile of the model they serve.

- **Evidence-Grounded Design:** Harness changes should be motivated by systematic failure analysis (Weakness Mining) rather than human intuition.

- **Stability through Validation:** A rigorous regression gate is essential to prevent "catastrophic forgetting" or the introduction of new bugs during the improvement process.

Self-Harness provides a scalable path forward for building increasingly autonomous agents. As these systems move into more complex, open-ended environments, the ability to self-correct and self-refine their interaction logic will be a fundamental requirement for reliability and efficiency.

[Meta-harness: End-to-end optimization of model harnesses](https://www.alphaxiv.org/abs/2603.28052)This paper is frequently cited as the primary point of contrast to the Self-Harness paradigm. While Self-Harness enables an agent to improve its own harness, Meta-Harness uses a stronger, external agent to optimize the harness of a weaker one, making it essential for understanding the specific novelty of the presented work.Yoonho Lee, Roshen Nair, Qizheng Zhang, Kangwook Lee, Omar Khattab, and Chelsea Finn. Meta-harness: End-to-end optimization of model harnesses, 2026. URL https://arxiv.org/abs/2603.28052.[Reflexion: Language agents with verbal reinforcement learning](https://www.alphaxiv.org/abs/2303.11366)Reflexion is a foundational paper on agent self-improvement where agents learn from verbal feedback on their past execution traces. This is directly relevant to the &#x27;Weakness Mining&#x27; stage of Self-Harness, which similarly analyzes failed traces to identify patterns and generate improvements.Noah Shinn, Federico Cassano, Edward Berman, Ashwin Gopinath, Karthik Narasimhan, and Shunyu Yao. Reflexion: Language agents with verbal reinforcement learning, 2023. URL https://arxiv.org/abs/2303.11366.[Swe-bench: Can language models resolve real-world github issues?](https://www.alphaxiv.org/abs/2310.06770)This paper introduces SWE-bench, one of the three core benchmarks used to experimentally validate the Self-Harness framework. The effectiveness of Self-Harness is extensively demonstrated through its performance on SWE-bench Verified, making this citation crucial for understanding the paper&#x27;s experimental setup and results.Carlos E. Jimenez, John Yang, Alexander Wettig, Shunyu Yao, Kexin Pei, Ofir Press, and Karthik Narasimhan. Swe-bench: Can language models resolve real-world github issues?, 2024. URL https://arxiv.org/abs/2310.06770.[React: Synergizing reasoning and acting in language models](https://www.alphaxiv.org/abs/2210.03629)The ReAct framework is cited as a foundational example of a &#x27;harness&#x27; that mediates an agent&#x27;s interaction with its environment. It establishes the importance of the harness concept itself, providing the essential background and motivation for why developing automated methods for harness improvement, like Self-Harness, is a significant research problem.Shunyu Yao, Jeffrey Zhao, Dian Yu, Nan Du, Izhak Shafran, Karthik Narasimhan, and Yuan Cao. React: Synergizing reasoning and acting in language models, 2023. URL https://arxiv.org/abs/2210.03629.## Audio

Generate audio summary→## Similar papers

[A Self-Improving Coding Agent16 May 2025](/abs/2504.15228)[Meta-Harness: End-to-End Optimization of Model Harnesses30 Mar 2026](/abs/2603.28052)[Agentic Harness Engineering: Observability-Driven Automatic Evolution of Coding-Agent Harnesses18 May 2026](/abs/2604.25850)[HarnessX: A Composable, Adaptive, and Evolvable Agent Harness Foundry23 Jul 2026](/abs/2606.14249)[LongHorizon-Harness: Advancing Long-Horizon Agents for Real-World Tasks03 Aug 2026](/abs/2608.01964)Show moreShow less[Meta Context Engineering via Agentic Skill Evolution11 Feb 2026](/abs/2601.21557)[SIA: Self Improving AI with Harness & Weight Updates28 May 2026](/abs/2605.27276)[Recursive Harness Self-Improvement17 Jul 2026](/abs/2607.15524)[HarnessOpt-Bench: Evaluating LLMs at Harness Optimization06 Aug 2026](/abs/2608.06301)[Adapting

... [Content truncated]