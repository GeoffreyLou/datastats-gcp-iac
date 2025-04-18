# 🚀 Datastats GCP IaC

This repository is a part of <strong>Datastats</strong> x <strong>GCP</strong> project. 


## ✨ Datastats x GCP purpose

The purpose of this project is to retrieve daily job offers in the data professions to monitor market trends and the technologies in demand. 


## 🤔 What is this IaC repository ?

This repository contains the Infrastructure as Code for the entire project, utilizing Terraform.

It enables the creation of all project resources, ensuring that no resources are created manually.

To minimize costs, the development environment is only used during coding, which is why CI/CD is only activated on the **main** branch.

**No sensitive variables are stored in this repository.**

## 👷🏻‍♀️ Architecture

![Datastats global architecture](assets/datastats.png)


## 💡 What's next ? 

What will be added to this repository?
- DBT Cloud Run + Scheduler
- Monthly Analyzer Cloud Run + Scheduler
- Dataviz solution (Looker, Metabase, TBD) with public URL