const particlesContainer = document.getElementById('particles');
const scrollProgress = document.getElementById('scrollProgress');
const scrollProgressText = document.getElementById('scrollProgressText');
const scrollToTopBtn = document.getElementById('scrollToTop');
const fixedFooter = document.getElementById('fixedFooter');
const sections = Array.from(document.querySelectorAll('.page-section'));
const navContainer = document.querySelector('.nav-items');

scrollToTopBtn?.addEventListener('click', scrollToTop);
const navItems = Array.from(document.querySelectorAll('.nav-item'));
const parallaxShapes = Array.from(document.querySelectorAll('.parallax-shape'));
const sectionTitles = Array.from(document.querySelectorAll('.section-title'));

function createParticles() {
    for (let i = 0; i < 30; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.left = `${Math.random() * 100}%`;
        particle.style.animationDelay = `${Math.random() * 20}s`;
        particle.style.animationDuration = `${Math.random() * 10 + 15}s`;
        particlesContainer.appendChild(particle);
    }
}

function scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateScrollProgress(scrollTop) {
    const docHeight = Math.max(document.documentElement.scrollHeight - window.innerHeight, 1);
    const scrollPercent = Math.round((scrollTop / docHeight) * 100);
    scrollProgress.style.width = `${scrollPercent}%`;
    scrollProgressText.textContent = `${scrollPercent}%`;
}

function updateFooter(scrollTop) {
    fixedFooter.classList.toggle('visible', scrollTop > 100);
}

function updateScrollToTop(scrollTop) {
    scrollToTopBtn.classList.toggle('visible', scrollTop > 500);
}

function updateActiveNav(scrollTop) {
    const currentOffset = scrollTop + 200;
    let activeSectionId = sections[0]?.id || '';
    sections.forEach(section => {
        const top = section.offsetTop;
        const bottom = top + section.offsetHeight;
        if (currentOffset >= top && currentOffset < bottom) {
            activeSectionId = section.id;
        }
    });
    navItems.forEach(item => item.classList.toggle('active', item.dataset.section === activeSectionId));
}

function updateParallax(scrollTop) {
    parallaxShapes.forEach((shape, index) => {
        const speed = (index + 1) * 0.1;
        shape.style.transform = `translateY(${scrollTop * speed}px) rotate(${scrollTop * 0.02}deg)`;
    });
}

function handleScroll() {
    const scrollTop = window.scrollY;
    updateScrollProgress(scrollTop);
    updateFooter(scrollTop);
    updateScrollToTop(scrollTop);
    updateActiveNav(scrollTop);
    updateParallax(scrollTop);
    ticking = false;
}

let ticking = false;
window.addEventListener('scroll', () => {
    if (!ticking) {
        window.requestAnimationFrame(handleScroll);
        ticking = true;
    }
});

navContainer.addEventListener('click', event => {
    const link = event.target.closest('.nav-item');
    if (!link) return;
    event.preventDefault();
    const sectionId = link.dataset.section || link.getAttribute('href')?.slice(1);
    const section = document.getElementById(sectionId);
    section?.scrollIntoView({ behavior: 'smooth' });
});

const observerOptions = {
    threshold: 0.12,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        const target = entry.target;
        target.classList.add('visible');

        if (target.classList.contains('page-section')) {
            const cards = target.querySelectorAll('.product-card');
            cards.forEach((card, index) => {
                setTimeout(() => card.classList.add('visible'), index * 120);
            });
        }

        observer.unobserve(target);
    });
}, observerOptions);

sectionTitles.forEach(el => observer.observe(el));
sections.forEach(section => observer.observe(section));

document.addEventListener('touchstart', event => {
    touchStartY = event.changedTouches[0].screenY;
}, { passive: true });

document.addEventListener('touchend', event => {
    touchEndY = event.changedTouches[0].screenY;
    handleSwipe();
}, { passive: true });

let touchStartY = 0;
let touchEndY = 0;

function handleSwipe() {
    const currentScroll = window.scrollY;
    const screenHeight = window.innerHeight;
    const swipeDistance = touchStartY - touchEndY;

    if (swipeDistance > 50) {
        window.scrollTo({ top: currentScroll + screenHeight, behavior: 'smooth' });
    } else if (swipeDistance < -50) {
        window.scrollTo({ top: Math.max(0, currentScroll - screenHeight), behavior: 'smooth' });
    }
}

window.addEventListener('load', () => {
    createParticles();
    handleScroll();
});
