# Adepa Pharmacy — From Semantic HTML to a Deployed Responsive Website

## 1. Project Overview

I created this responsive pharmacy website for Adepa Pharmacy in Kumasi, Ghana. The website presents the pharmacy’s services, gallery, background information, contact form, and opening hours.

## 2. Project Goals

I wanted to:

- Create a clear and professional pharmacy website
- Practise semantic HTML structure
- Build a responsive layout for mobile and desktop
- Make the content accessible to different users
- Deploy the project using GitHub Pages

## 3. Technologies

- HTML5
- CSS3
- Tailwind CSS
- Formspree
- Git and GitHub
- GitHub Pages

## 4. What I Built

I created:

- A navigation header with links to each page section
- A hero section with the main pharmacy message
- Responsive service cards
- A gallery using images, figures, and captions
- An about section with a customer testimonial
- A contact form
- An Opening Hours section beside the contact form
- A responsive footer with pharmacy contact information

## 5. JOMACS Module 1.2 Skills Applied

I applied the skills I learned in the JOMACS module, including:

- Writing structured HTML
- Using semantic HTML elements
- Creating forms with labels and input controls
- Styling pages with CSS
- Using responsive layouts
- Adding images with meaningful alternative text
- Using Git and GitHub to manage and publish my project

## 6. Key Challenges & How I Solved Them

### Correcting the hero structure

The hero section initially had closing tags in the wrong position. I reorganised the HTML so that all hero content is properly contained inside the section and its container.

### Improving the hero layout

I adjusted the hero CSS to make the height content-driven instead of using excessive vertical space. I also aligned the heading to the left and allowed the description and services link to wrap naturally on smaller screens.

### Moving Opening Hours

I moved the Opening Hours `<aside>` inside the contact section so it appears beside the form on larger screens and stacks below it on smaller screens.

### Removing the page-level sidebar

I removed the old sidebar grid layout because it was creating unnecessary page-level spacing and did not match the intended contact-section design.

### Connecting the contact form

I connected the form to Formspree so visitors can submit enquiries without requiring a custom backend.

## 7. Accessibility & Semantic HTML

I used semantic elements including:

- `<header>`
- `<nav>`
- `<main>`
- `<section>`
- `<article>`
- `<figure>`
- `<figcaption>`
- `<blockquote>`
- `<form>`
- `<fieldset>`
- `<legend>`
- `<aside>`
- `<dl>`, `<dt>`, and `<dd>`
- `<footer>`

I also:

- Kept one main `<h1>` heading
- Added meaningful image `alt` text
- Associated labels with form inputs
- Added keyboard focus styles
- Preserved logical navigation order
- Added image width and height attributes

## 8. Responsive Layout & CSS

I used Tailwind CSS utility classes and custom CSS to create responsive layouts.

The website:

- Displays service cards in columns on larger screens
- Stacks content on smaller screens
- Places the contact form and Opening Hours side by side on desktop
- Stacks the contact content vertically on mobile
- Prevents unnecessary horizontal overflow
- Uses flexible spacing and responsive typography

## 9. Form Handling with Formspree

I used Formspree to handle contact form submissions.

The form includes:

- Full name
- Email address
- Phone number
- Preferred contact method
- Message
- Required fields
- Accessible labels
- A submission subject
- A redirect destination after submission

## 10. Git, GitHub & Deployment

I used Git to track my changes and GitHub to store the project repository.

I also:

- Committed my HTML and CSS changes
- Resolved a remote repository update before pushing
- Pushed the final changes to the `main` branch
- Published the website using GitHub Pages

## 11. Working with AI and Reviewing Code

I used AI as a development assistant to help me:

- Identify incorrect HTML nesting
- Review layout and CSS issues
- Suggest responsive improvements
- Check semantic and accessibility concerns
- Improve the README documentation

I reviewed the suggested changes and applied the relevant edits to my project rather than accepting changes without checking them.

## 12. What I Learned

I learned that small HTML structure problems can affect the entire page layout. I also learned how important it is to keep CSS layout rules consistent with the HTML structure.

This project helped me improve my understanding of:

- Semantic HTML
- Responsive design
- CSS grid and flexbox
- Accessible forms
- Git workflows
- GitHub Pages deployment
- Reviewing and debugging code

## 13. Live Demo

[View the live website](https://davidtettehpadi.github.io/adepa-pharmacy/)

## 14. Repository

[View the GitHub repository](https://github.com/DavidTettehPadi/adepa-pharmacy.git)
