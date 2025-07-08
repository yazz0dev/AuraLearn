# Aura ✨ - Your Proactive AI Tutor



**Aura is a next-generation personalized learning companion designed to guide university students through their semester curriculum. Unlike passive Q&A bots, Aura is a proactive tutor that schedules your learning, introduces topics, asks probing questions, and adapts to your personal pace, ensuring you master every concept based on a grounded, curated knowledge base.**

---

## Table of Contents

- [The Philosophy Behind Aura](#the-philosophy-behind-aura)
- [How It Works](#how-it-works)
- [Key Features](#key-features)
- [A Sample Student Interaction](#a-sample-student-interaction)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Grounding Aura: The Source Material](#grounding-aura-the-source-material)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## The Philosophy Behind Aura

Traditional learning can be isolating and inefficient. Students are often left to passively consume dense textbooks and lecture notes, with no one to guide them or check their understanding in real-time. Aura was built on three core principles to solve this:

1.  **🧠 Proactive, Not Reactive:** Learning shouldn't wait for you to get stuck. Aura takes the lead. It initiates learning sessions, introduces new concepts according to your syllabus, and actively checks your understanding, transforming you from a passive reader into an active participant.

2.  **📚 Grounded in Curated Knowledge:** The internet is full of noise. Aura's knowledge is not based on the entire web, but is **strictly grounded in the source materials you provide**—your university syllabus, textbooks, lecture notes, and research papers. This ensures every piece of information is accurate, relevant, and directly aligned with your course.

3.  **🏃‍♀️ Learning at Your Pace, Within a Structure:** A semester is a marathon, not a sprint. Aura creates a 6-month (or any specified duration) schedule based on your syllabus. While the overall structure is set, you have the flexibility to tackle each topic at your own speed. Spend more time on difficult concepts and breeze through familiar ones, all while Aura ensures you stay on track to finish on time.

## How It Works

Aura acts as your dedicated semester-long guide. The process is simple and student-focused.

1.  **Onboarding:** You (or the administrator) provide Aura with a course syllabus and the corresponding source materials (e.g., PDFs of textbooks, markdown files of notes).
2.  **Semester Scheduling:** Aura analyzes the syllabus and the material, creating a personalized 6-month learning plan. It breaks down the entire course into manageable topics and schedules them across the semester.
3.  **Proactive Sessions:** Aura will reach out to you at scheduled times (e.g., "Good morning! Ready to spend 20 minutes on 'The Krebs Cycle' today?").
4.  **Socratic Dialogue:** During a session, Aura will:
    *   Introduce a concept, referencing the source material.
    *   Ask you questions to gauge your understanding.
    *   Explain concepts in different ways if you're struggling.
    *   Connect new topics to what you've already learned.
5.  **Continuous Feedback & Adaptation:** Aura tracks your progress. If you consistently struggle with a topic, it will schedule a review session. If you master a topic quickly, it will adjust the pace accordingly.

## Key Features

-   **Proactive Session Initiation:** Aura messages the student to start a learning session.
-   **Syllabus-Driven Scheduling:** Automatically generates a semester-long (e.g., 24-week) schedule.
-   **Grounded Q&A:** Answers questions based *only* on the provided academic sources, preventing hallucination and misinformation.
-   **Personalized Pacing:** The student's interaction and performance dictate the speed of topic progression.
-   **Socratic Method:** Teaches by asking questions, forcing critical thinking rather than simple memorization.
-   **Knowledge Scaffolding:** Intelligently links new topics to previously learned concepts.
-   **Progress Tracking:** Monitors which topics have been covered, which need review, and overall progress through the semester.
-   **Easy Configuration:** Simple `config.yml` to define the course, syllabus, and source material location.

## A Sample Student Interaction

This example shows Aura initiating a session for an "Economics 101" course.

> **Aura:**
> `Hi Alex! We've scheduled our first topic for ECON101 today. Got 15-20 minutes to dive into the "Law of Demand"?`
>
> **Student (Alex):**
> `Sure, I'm ready.`
>
> **Aura:**
> `Great. Let's start with the core principle from our source text, 'Principles of Microeconomics', Chapter 3: The law of demand states that, all other factors being equal, as the price of a good increases, consumer demand for it decreases.`
>
> `Before we dig deeper, can you think of a simple, everyday example of this in your own life?`
>
> **Student (Alex):**
> `Hmm, maybe like when the price of avocados goes up at the grocery store, I buy them less often.`
>
> **Aura:**
> `That's a perfect example! It captures the inverse relationship between price and quantity demanded. Now, the principle mentions "all other factors being equal." Can you guess what might be one of those "other factors" that could make you buy *more* avocados, even if the price was high?`

## Getting Started

Ready to set up your own Aura instance? Follow these steps.

### Prerequisites

-   Python 3.8+
-   An OpenAI API Key (or other LLM provider)
-   Your course materials (see [Grounding Aura](#grounding-aura-the-source-material))

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/aura-tutor.git
cd aura-tutor

# Install dependencies
pip install -r requirements.txt
```

### Configuration

All course-specific settings are managed in `config.yml`. Create your own or modify the example.

```yaml
# config.yml

# Course Information
course_name: "ECON101: Principles of Microeconomics"
semester_duration_weeks: 24

# Path to the syllabus file (can be .txt or .md)
# Aura uses this to structure the semester.
syllabus_file: "course_data/econ101_syllabus.txt"

# Path to the folder containing all curated source documents
# Supported formats: .txt, .md, .pdf
source_material_path: "course_data/sources/"

# Student & AI Configuration
student_name: "Alex"
ai_model: "gpt-4-turbo" # Or your model of choice

# API Keys - loaded from environment variables for security
openai_api_key: "${OPENAI_API_KEY}"
```

## Grounding Aura: The Source Material

The quality of Aura's tutoring depends entirely on the quality of the source material.

1.  **Create a Directory:** In the project, create a directory for your course (e.g., `course_data/`).
2.  **Add Syllabus:** Place your course syllabus inside this directory. This file should list the topics in the order they will be taught.
3.  **Add Sources:** Create a `sources/` subdirectory and place all your grounded material inside:
    -   `chapter1.pdf`
    -   `lecture_notes_week1.md`
    -   `key_concepts.txt`
    -   `research_paper_on_demand.pdf`

Aura will process, index, and exclusively use these files for all its interactions.

## Roadmap

Aura is an evolving project. Here's what's planned for the future:
pending....
