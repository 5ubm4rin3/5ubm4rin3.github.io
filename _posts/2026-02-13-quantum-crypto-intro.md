---
title: "양자 내성 암호(PQC)와 격자 기반 문제"
date: 2026-02-13 22:00:00 +0900
categories: [Cryptography, Quantum]
tags: [pqc, lattice, security]
math: true
---

## Introduction
양자 컴퓨터의 등장은 기존 RSA, ECC 암호 체계를 위협합니다. 이를 해결하기 위한 **양자 내성 암호(Post-Quantum Cryptography)** 중 격자 기반 암호에 대해 알아봅니다.

## Mathematical Foundation
격자(Lattice) 상에서의 최단 벡터 문제(SVP)는 다음과 같이 정의됩니다.

$$\| \sum_{i=1}^n x_i \mathbf{b}_i \| \leq \| \mathbf{v} \|$$

## Roadmap
1. Kyber 알고리즘 분석
2. Dilithium 서명 체계 구현
3. 블록체인 노드 보안 적용 실험
