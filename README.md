# Ant Colony Search for Time-Windowed Vehicle Routing Problem (ACS-VRPTW)

(the code is part of my BSc Thesis about Swarm-Intelligence applications)  
link: https://diplomaterv.vik.bme.hu/hu/Theses/Rajintelligencia-modszerek-hatekonysaganak

## Abstract

Over the past 15-20 years, computational intelligence has undergone considerable evolution, with the development of bio-inspired computational techniques becoming increasingly diversified. Concurrently, there has been a growing demand for efficient algorithms from the various, increasingly specialized fields of engineering design. Swarm intelligence represents a contemporary discipline within artificial intelligence, functioning analogously to certain biological mechanisms wherein populations composed of numerous individuals exhibit collective intelligent behavior through individually goal-driven actions. Systems embodying such behavioral patterns, such as populations of ants, bees, birds, and many other animal/insect species, possess attributes desirable for integration into our engineered multi-agent systems, necessitating significant fault tolerance, flexibility, and self-organizing capabilities.

Efficient computational algorithms have previously existed for optimization within evolutionary methods, thus raising a legitimate inquiry: what does swarm intelligence contribute in these realms? The response to this query can be encapsulated by a straightforward assertion: efficient decentralized biological mechanisms operating in nature are characterized by robustness, scalability, adaptability, and a propensity for self-organization. Algorithms crafted from a swarm intelligence perspective inherently embody these characteristics, facilitating the efficient resolution of complex optimization tasks. The discourse will cover the two paramount algorithms: Ant Colony Optimization and Particle Swarm Optimization, along with the popular Artificial Bee Colony Optimization.

Administered by the Center for Connected Learning (CCL), a programmable multi-agent modeling environment named NetLogo is available, primarily aimed at the study of complex multi-agent systems. This framework offers an exceptional opportunity for the visualization of decentralized systems encountered within the domain of swarm intelligence. Swarm intelligence introduces a fundamentally new perspective on the potential developmental directions of multi-agent systems. This paper aims to showcase several significant research projects from the world of swarm intelligence-inspired robotics: SYMBRION-REPLICATOR and Swarm-bots, coordinated by Marco Dorigo.

In summary, the objective of this thesis is to contextualize swarm intelligence within the current landscape of evolutionary computational techniques, examining both its usability and structural characteristics, as well as analyzing its potential, limitations, and contemporary achievements. An additional goal is to present visualizations using NetLogo software that facilitate a better understanding of the efficacy of swarm intelligence methods, followed by an overview of the aforementioned robotics research projects.

(the summary below is written by GPT 4.0, might contain errors!) I will add the original paper as soon as I find it.

## Overview
This project implements an advanced optimization technique using Ant Colony Search (ACS) to solve the Time-Windowed Vehicle Routing Problem (VRPTW), a complex variant of the classic Traveling Salesman Problem. The goal is to design efficient routes for a fleet of vehicles to deliver goods to various locations within specific time windows, optimizing total travel cost and fleet size. The solution is particularly relevant for logistics, delivery services, and transportation planning.

## Features
Dual-ACS Implementation: The project is structured into three MATLAB scripts, each playing a pivotal role in the optimization process:

- Dual-ACS.m: The main script initializes the problem parameters, sets up the environment, and orchestrates the running of the ACS algorithms for vehicle routing and time scheduling.
- ACS_Vehicle.m: Focuses on minimizing the fleet size required to fulfill all deliveries within the given constraints.
- ACS_Time.m: Aims to optimize the routing and scheduling to minimize the total cost, ensuring all deliveries are made within the specified time windows.
Clarke-Wright Savings Algorithm Integration: The solution incorporates the Clarke-Wright Savings Algorithm for an initial solution, which is then refined through the ACS approach for improved efficiency.

Dynamic Parameter Adjustment: Includes mechanisms for dynamically adjusting parameters such as the number of ants, pheromone evaporation rate, and the balance between exploration and exploitation, ensuring robustness and adaptability in finding optimal solutions.

Visualization and Analysis: Provides tools for visualizing the routing solutions and analyzing the performance of the algorithms in terms of total cost and fleet size reduction.

## Dependencies
MATLAB: The project is developed in MATLAB, leveraging its computational tools and visualization capabilities for efficient algorithm implementation and result analysis.

## Usage
To execute the project:

Open Dual-ACS.m in MATLAB.
Adjust the parameters as needed to match your specific VRPTW instance or to experiment with different optimization settings.
Run the script to initiate the optimization process. The console will display progress updates and final results, including the optimized fleet size and total cost.
Explore the generated plots for a visual representation of the optimization process and outcomes.

## License
This project is open-source and available under the MIT License. See the LICENSE file for more details.

## Acknowledgments
This project was inspired by my research on biological-based algorithms. Special thanks to lecturers and my consultant who have made this project possible.



