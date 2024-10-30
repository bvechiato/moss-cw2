## Overview
We will use Git for version control to track changes in our code and collaborate effectively. This README will guide you through the basics of using Git, ensuring everyone can contribute smoothly.

## Prerequisites
Make sure Git is installed on your computer. You can download it from git-scm.com.

### Setting Up Git
To start working on the project, you'll need to clone the repository to your local machine. Open your command line or terminal and run the following command:

```bash
git clone https://github.com/bvechiato/moss-cw2
```
#### Navigate to the Project Directory
Change into the project directory using:

```bash
cd moss-cw2
```

### How-to
1. Before starting new work, always pull the latest changes from the remote repository to ensure you have the most up-to-date version:

```bash
git pull
```
2. If you're working on a new feature or significant changes, it's a good practice to create a new branch:

```bash
git checkout -b [branch-name]
```
Replace [branch-name] with a descriptive name for your task.

3. You can check the status of your files using:

```bash
git status
```
This command shows you which files are modified, staged, or untracked.

4. After modifying your files, "stage" them for commit:

```bash
git add .
```

5. Once your changes are staged, commit them with a descriptive message:

```bash
git commit -m "Description of changes made"
```
6. To share your changes with the team, push your commits to your branch:

```bash
git push
```

7. After finishing work on a branch, you can merge it back into the main branch:

First, switch to the main branch:

```bash
git checkout main
```
Then, merge your branch:

```bash
git merge [branch-name]
```

### Best Practices
1. Commit frequently: make small, frequent commits with descriptive messages.
2. Pull regularly: pull changes from the main branch often to minimise conflicts.
3. Use meaningful branch names: name branches descriptively to indicate their purpose (e.g., feature/add-agent-attributes).