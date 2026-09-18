# Adepa Pharmacy Website

A responsive pharmacy website I built as part of my **JOMACS Fullstack Development** course and **Modern UI Engineering** assignment.

The project represents Adepa Pharmacy, a fictional local pharmacy in Asokwa, Kumasi, Ghana. My goal was to create a professional business website while applying the UI Engineering principles I was learning.

## Project Overview

This project helped me practise:

- Semantic HTML5
- Responsive UI design
- Tailwind CSS and CSS
- Accessible forms and navigation
- Git and GitHub
- Static website deployment
- Frontend testing and debugging

## Features

- Responsive navigation
- Hero section with clear calls to action
- Pharmacy services section with three service cards
- About section and customer testimonial
- Pharmacy image gallery
- Opening hours
- Accessible contact form
- Formspree integration
- Custom thank-you page
- Responsive layout for mobile and desktop

## Semantic HTML & Accessibility

I focused on using HTML elements according to their meaning rather than relying on generic containers.

The site uses elements such as:

- `<header>`
- `<nav>`
- `<main>`
- `<section>`
- `<article>`
- `<aside>`
- `<figure>`
- `<blockquote>`
- `<dl>`, `<dt>`, and `<dd>`
- `<form>`
- `<fieldset>` and `<legend>`
- `<footer>`

I also added meaningful image `alt` text, explicit image dimensions, properly associated form labels, and visible keyboard focus states.

## Testing & Verification

I did not rely only on how the website looked in the browser. I also tested the structure and usability of the page.

| Check                            | Result |

| W3C HTML Validator       ✅      | 0 errors, 0 warnings |
| HeadingsMap              ✅      | Correct heading hierarchy |
| One H1                   ✅ 
| Form labels              ✅ 
| Fieldset and legend      ✅ 
| Keyboard navigation      ✅ 
| Visible keyboard focus   ✅ 
| Mobile navigation        ✅ 

The page was also tested locally using **Live Server**.

## Contact Form

The website is static, so I used **Formspree** to handle form submissions.

The form collects:

- Full name
- Email address
- Phone number
- Preferred contact method
- Message

After a successful submission, the user is redirected to a custom thank-you page.

## Challenges & Lessons

One of the most useful parts of this project was learning how to debug instead of simply making changes until the page looked right.

For example, the W3C validator initially identified an error in my navigation structure. I traced the problem to the `<ul>` and `<li>` relationship, corrected it, and revalidated the page successfully.

I also fixed duplicate form markup and tested the navigation and form using only the keyboard.

These challenges helped me understand that good frontend development involves **building, testing, debugging, and verifying**.

## Technologies

- HTML5
- CSS3
- Tailwind CSS
- Formspree
- Git
- GitHub
- GitHub Pages
- VS Code
- Live Server

## Project Structure

```text
adepa-pharmacy/
├── index.html
├── styles.css
├── thank-you.html
├── Pharmacist.png
├── medicine on counter.png
├── pharmacist and client.png
└── README.md

## Live Demo

[View the live website](https://davidtettehpadi.github.io/adepa-pharmacy/)

## GitHub Repository

[View the source code on GitHub](https://github.com/DavidTettehPadi/adepa-pharmacy)
