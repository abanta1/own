# Legacy Win32 Ownership Tool

> A low-level utility to force-change file ownership using direct Windows API calls.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/username/projectname/actions)

## 📖 About

This project is a technical demonstration of interacting with the Windows Security Subsystem using Visual Basic 6.0. It solves a specific administrative limitation: while the native takeown command only allows a user to take ownership for themselves, this tool enables an administrator to assign ownership to any arbitrary user or group by manually elevating process privileges.

## ✨ Key Features

*   **Feature One:** Description of the feature and its benefit.
*   **Feature Two:** Description of the feature and its benefit.
*   **Feature Three:** Description of the feature and its benefit.

Privilege Escalation: Programmatically enables SeRestorePrivilege to allow ownership assignment.

Direct API Integration: Uses advapi32.dll to manipulate Security Identifiers (SIDs) and Security Descriptors.

Zero Dependencies: A standalone executable that does not require the .NET runtime.

## 🛠️ Tech Stack

*   **Frontend:** [React](https://reactjs.org/), [Tailwind CSS](https://tailwindcss.com/)
*   **Backend:** [Node.js](https://nodejs.org/), [Express](https://expressjs.com/)
*   **Database:** [PostgreSQL](https://www.postgresql.org/)
*   **DevOps:** [Docker](https://www.docker.com/), [AWS](https://aws.amazon.com/)

Language: Visual Basic 6.0

APIs: Win32 API (Advapi32, Kernel32)

Platform: Windows XP / Windows Server 2003 Legacy Environment

## 🚀 Getting Started

Follow these instructions to get a local copy of the project up and running.

### Prerequisites

List things the user needs to install the software (e.g., Node.js, Python, etc.).

*   Visual Basic 6.0 IDE (to compile from source).
*   Administrative privileges (required to adjust token privileges).

### Installation

1.  Clone the repository
    ```sh
    git clone https://github.com/abanta1/own.git
    ```
2.  Navigate to the project directory
    ```sh
    cd projectname
    ```
3.  Open ``` Project1.vbp``` in the VB6 IDE.
    
4.  Go to ```File > Make Project1.exe```
    
## 💡 Usage

Provide examples of how to use the project. You can include code snippets or screenshots here.
``` cmd
\\ example usage
own.exe C:\Path\To\Folder,Username
```