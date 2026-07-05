function waitForElement(els, func, timeout = 100) {
  const queries = els.map((el) => document.querySelector(el));

  if (queries.every(Boolean)) {
    func(queries);
  } else if (timeout > 0) {
    setTimeout(waitForElement, 300, els, func, timeout - 1);
  }
}

waitForElement([".Root__top-container"], ([topContainer]) => {
  const root = document.documentElement;
  const styles = getComputedStyle(root);

  const starColor =
    styles.getPropertyValue("--spice-star").trim() || "#ffffff";

  const shootingStarRGB =
    styles
      .getPropertyValue("--spice-rgb-shooting-star-glow")
      .trim() || "255,255,255";

  const container = document.createElement("div");
  container.className = "starrynight-bg-container";

  Object.assign(container.style, {
    position: "absolute",
    inset: "0",
    overflow: "hidden",
    pointerEvents: "none",
    zIndex: "0",
  });

  topContainer.appendChild(container);

  const canvas = document.createElement("canvas");

  Object.assign(canvas.style, {
    position: "absolute",
    inset: "0",
    width: "100%",
    height: "100%",
    pointerEvents: "none",
  });

  container.appendChild(canvas);

  const ctx = canvas.getContext("2d");

  let width = 0;
  let height = 0;
  let dpr = window.devicePixelRatio || 1;

  const stars = [];
  const shootingStars = [];

  function rand(min, max) {
    return Math.random() * (max - min) + min;
  }

  function resize() {
    width = container.clientWidth;
    height = container.clientHeight;

    dpr = window.devicePixelRatio || 1;

    canvas.width = width * dpr;
    canvas.height = height * dpr;

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    createStars();
  }

  function createStars() {
    stars.length = 0;

    const count = Math.floor((width * height) / 12000);

    for (let i = 0; i < count; i++) {
      stars.push({
        x: rand(0, width),
        y: rand(0, height),
        r: Math.random() < 0.5 ? 1 : 2,
        phase: rand(0, Math.PI * 2),
        speed: rand(0.3, 1.0),
        brightness: rand(0.5, 1.0),
        twinkle: Math.random() < 0.05,
      });
    }
  }

  function spawnShootingStar() {
    const fromTop = Math.random() < 0.75;

    shootingStars.push({
      x: fromTop ? rand(width * 0.1, width * 0.9) : width + 100,
      y: fromTop ? -100 : rand(0, height * 0.5),

      vx: -700,
      vy: 700,

      life: 0,
      maxLife: rand(0.8, 1.5),

      length: rand(80, 180),
    });
  }

  for (let i = 0; i < 4; i++) {
    setTimeout(
      function loop() {
        spawnShootingStar();

        setTimeout(
          loop,
          rand(2000, 8000),
        );
      },
      rand(0, 6000),
    );
  }

  let lastTime = performance.now();

  function frame(now) {
    const dt = (now - lastTime) / 1000;
    lastTime = now;

    ctx.clearRect(0, 0, width, height);

    //
    // stars
    //
    ctx.fillStyle = starColor;

    for (const star of stars) {
      let alpha = star.brightness;

      if (star.twinkle) {
        alpha *=
          0.7 +
          0.3 *
            Math.sin(
              now * 0.001 * star.speed +
                star.phase,
            );
      }

      ctx.globalAlpha = alpha;

      ctx.beginPath();
      ctx.arc(
        star.x,
        star.y,
        star.r,
        0,
        Math.PI * 2,
      );
      ctx.fill();
    }

    //
    // shooting stars
    //
    for (let i = shootingStars.length - 1; i >= 0; i--) {
      const s = shootingStars[i];

      s.life += dt;

      if (s.life >= s.maxLife) {
        shootingStars.splice(i, 1);
        continue;
      }

      s.x += s.vx * dt;
      s.y += s.vy * dt;

      const t = s.life / s.maxLife;
      const alpha = 1 - t;

      const tailX =
        s.x - (s.vx / 1000) * s.length;
      const tailY =
        s.y - (s.vy / 1000) * s.length;

      const grad = ctx.createLinearGradient(
        s.x,
        s.y,
        tailX,
        tailY,
      );

      grad.addColorStop(
        0,
        `rgba(${shootingStarRGB},${alpha})`,
      );

      grad.addColorStop(
        1,
        `rgba(${shootingStarRGB},0)`,
      );

      ctx.strokeStyle = grad;
      ctx.lineWidth = 2;

      ctx.beginPath();
      ctx.moveTo(s.x, s.y);
      ctx.lineTo(tailX, tailY);
      ctx.stroke();
    }

    ctx.globalAlpha = 1;

    requestAnimationFrame(frame);
  }

  resize();

  const resizeObserver =
    new ResizeObserver(resize);

  resizeObserver.observe(container);

  requestAnimationFrame(frame);
});
