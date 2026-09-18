## Project Overview
I created this project as part of my JOMACS Fullstack Development assignment, and it serves as my first UI Engineering exercise. The goal was to design and build a professional and responsive website for Adepa Pharmacy, a local pharmacy business in Kumasi, Ghana.

I wanted the website to present the pharmacy in a clear and modern way, while also demonstrating my understanding of front-end design, layout, styling, and deployment. The project was built using HTML, CSS, and Tailwind CSS, with a functional contact form connected to Formspree.

## Objectives
I set out to achieve the following:
- create a professional business website for a pharmacy
- use semantic HTML for effective page structure
- apply responsive design principles
- use Tailwind CSS to style the interface
- add a functional contact form for enquiries
- deploy the project online using GitHub Pages

## Tools and Technologies I Used
I used the following tools and technologies:
- HTML5
- CSS3
- Tailwind CSS
- GitHub Pages
- Formspree
- Git and GitHub

## Features Included
I designed the website to include:
- a navigation bar
- a hero section with a strong business message
- a services section
- an about section
- a gallery section
- opening hours
- a contact form
- a thank-you page after successful form submission
- mobile-friendly responsive layout

## Design and Build Process
I began by planning the structure of the website and identifying the content that needed to be displayed. Then I created the semantic HTML structure and styled the page using Tailwind utility classes for layout, spacing, colors, and responsiveness.

I also created a small custom CSS file for a few design touches that were not handled directly by Tailwind. This approach allowed me to combine professional structure, utility-based styling, and a few custom enhancements.

## Contact Form Implementation
Because I was building a static website, I needed a way to allow users to submit enquiries without a back-end server. I solved this by integrating Formspree into the contact form. The form sends data to a Formspree endpoint, and after a successful submission, the user is redirected to a thank-you page.

## Challenges I Faced
During the development of this project, I faced several challenges.

### 1. Duplicate Form Markup
I encountered an issue where the contact form appeared twice because of duplicate HTML markup. I resolved this by removing the repeated section and keeping only one correct form.

### 2. Static Site Form Handling
Since the website is static, it could not send messages directly. I solved this by using Formspree, which allows form submissions to be handled without a server-side backend.

### 3. Deployment
I had to ensure the project was published correctly on GitHub Pages. I fixed the repo configuration, enabled GitHub Pages, and confirmed that the site could be accessed online.

### 4. Tailwind Requirement
The assignment required the use of HTML, CSS, and Tailwind. I integrated Tailwind into the project and used it to build the responsive layout, while still using a small amount of custom CSS for specific styling enhancements.

## Project Structure
```text
adepa-pharmacy/
├── index.html
├── styles.css
├── thank-you.html
├── Pharmacist.png
├── medicine on counter.png
├── pharmacist and client.png
├── README.md
```

## Live Demo
I deployed the website and it is available here:

```text
https://davidtettehpadi.github.io/adepa-pharmacy/
```

## How to Run the Project
I can run the website locally by opening the `index.html` file in a browser. Alternatively, I can clone the project and work on it from my local machine.

```bash
git clone https://github.com/DavidTettehPadi/adepa-pharmacy.git
cd adepa-pharmacy
open index.html
```

## Reflection
This project helped me improve my practical understanding of front-end web development. I learned how to structure a website using semantic HTML, style it using Tailwind and CSS, create a working contact form, and deploy a project online. It also strengthened my skills in debugging, iteration, and version control using Git and GitHub.

## Conclusion
I am pleased with the outcome of this project because it demonstrates my ability to design and implement a professional business website while applying the key technologies required for the assignment. It reflects my growth as a beginner UI engineer and my ability to turn a concept into a functioning, published website.
