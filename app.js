/*
   Application logic for Rubik Solver Web Version
   Handles color picker, interactive grid painting, validator, 
   Kociemba solving, and solution step player animations.
*/

document.addEventListener('DOMContentLoaded', () => {
  // --- Cube State & Config ---
  const faces = ['U', 'L', 'F', 'R', 'B', 'D'];
  const fixedCenters = {
    'U': 'yellow',
    'L': 'red',
    'F': 'green',
    'R': 'orange',
    'B': 'blue',
    'D': 'white'
  };

  const colorLabels = {
    'yellow': 'Kuning',
    'orange': 'Oranye',
    'green': 'Hijau',
    'white': 'Putih',
    'red': 'Merah',
    'blue': 'Biru',
    'none': 'Kosong'
  };

  const faceNames = {
    'U': 'Atas (Up)',
    'D': 'Bawah (Down)',
    'R': 'Kanan (Right)',
    'L': 'Kiri (Left)',
    'F': 'Depan (Front)',
    'B': 'Belakang (Back)',
  };

  const opposites = {
    'white': 'yellow',
    'yellow': 'white',
    'red': 'orange',
    'orange': 'red',
    'green': 'blue',
    'blue': 'green'
  };

  // 12 Edges mapping: {f1: Face, idx1: index, f2: Face, idx2: index}
  const edges = [
    { f1: 'U', idx1: 1, f2: 'B', idx2: 1 },
    { f1: 'U', idx1: 3, f2: 'L', idx2: 1 },
    { f1: 'U', idx1: 5, f2: 'R', idx2: 1 },
    { f1: 'U', idx1: 7, f2: 'F', idx2: 1 },
    { f1: 'D', idx1: 1, f2: 'F', idx2: 7 },
    { f1: 'D', idx1: 3, f2: 'L', idx2: 7 },
    { f1: 'D', idx1: 5, f2: 'R', idx2: 7 },
    { f1: 'D', idx1: 7, f2: 'B', idx2: 7 },
    { f1: 'F', idx1: 3, f2: 'L', idx2: 5 },
    { f1: 'F', idx1: 5, f2: 'R', idx2: 3 },
    { f1: 'B', idx1: 3, f2: 'R', idx2: 5 },
    { f1: 'B', idx1: 5, f2: 'L', idx2: 3 }
  ];

  // 8 Corners mapping: {f1, idx1, f2, idx2, f3, idx3}
  const corners = [
    { f1: 'U', idx1: 0, f2: 'L', idx2: 0, f3: 'B', idx3: 2 },
    { f1: 'U', idx1: 2, f2: 'B', idx2: 0, f3: 'R', idx3: 2 },
    { f1: 'U', idx1: 6, f2: 'F', idx2: 0, f3: 'L', idx3: 2 },
    { f1: 'U', idx1: 8, f2: 'R', idx2: 0, f3: 'F', idx3: 2 },
    { f1: 'D', idx1: 0, f2: 'L', idx2: 6, f3: 'F', idx3: 6 },
    { f1: 'D', idx1: 2, f2: 'F', idx2: 8, f3: 'R', idx3: 6 },
    { f1: 'D', idx1: 6, f2: 'B', idx2: 8, f3: 'L', idx3: 6 },
    { f1: 'D', idx1: 8, f2: 'R', idx2: 8, f3: 'B', idx3: 6 }
  ];

  // Initial Empty Cube State
  let cubeState = {};
  faces.forEach(f => {
    cubeState[f] = Array(9).fill('none');
    cubeState[f][4] = fixedCenters[f]; // Center is fixed
  });

  let selectedColor = 'yellow';
  let activeView = 'net'; // 'net' or 'single'
  let activeSingleFace = 'U';
  
  // Solution player state
  let solutionSteps = [];
  let currentStepIndex = 0;
  let isPlaying = false;
  let playInterval = null;

  // --- DOM Elements ---
  const loaderOverlay = document.getElementById('loader-overlay');
  const loaderTitle = document.getElementById('loader-title');
  const loaderSubtitle = document.getElementById('loader-subtitle');

  const btnNetView = document.getElementById('btn-net-view');
  const btnSingleView = document.getElementById('btn-single-view');
  const netViewContainer = document.getElementById('net-view-container');
  const singleViewContainer = document.getElementById('single-view-container');
  
  const singleFaceGrid = document.getElementById('single-face-grid');
  const currentFaceTitle = document.getElementById('current-face-title');
  const btnPrevFace = document.getElementById('btn-prev-face');
  const btnNextFace = document.getElementById('btn-next-face');
  const faceSelBtns = document.querySelectorAll('.face-sel-btn');

  const colorOptBtns = document.querySelectorAll('.color-opt-btn');
  const selectedColorLabel = document.getElementById('selected-color-label');
  const progressCount = document.getElementById('progress-count');
  const progressBar = document.getElementById('progress-bar');
  
  const btnReset = document.getElementById('btn-reset');
  const btnScramble = document.getElementById('btn-scramble');
  const btnSolve = document.getElementById('btn-solve');

  const validationPanel = document.getElementById('validation-panel');
  const errorList = document.getElementById('error-list');
  const emptySolutionPanel = document.getElementById('empty-solution-panel');
  const solutionPanel = document.getElementById('solution-panel');
  const solveTimeBadge = document.getElementById('solve-time');
  const algorithmNotation = document.getElementById('algorithm-notation');

  const stepCounter = document.getElementById('step-counter');
  const stepNotationBadge = document.getElementById('step-notation-badge');
  const visualizerFace = document.getElementById('visualizer-face');
  const arrowPath = document.getElementById('arrow-path');
  const stepFaceTitle = document.getElementById('step-face-title');
  const stepDescText = document.getElementById('step-desc-text');
  
  const btnStepPrev = document.getElementById('btn-step-prev');
  const btnStepPlay = document.getElementById('btn-step-play');
  const playIcon = document.getElementById('play-icon');
  const btnStepNext = document.getElementById('btn-step-next');
  const stepsScrollList = document.getElementById('steps-scroll-list');

  // --- Solver Initialization ---
  console.log("Initializing solver tables...");
  setTimeout(() => {
    try {
      if (window.Cube && typeof window.Cube.initSolver === 'function') {
        window.Cube.initSolver();
        console.log("Solver tables initialized.");
        loaderTitle.textContent = "Inisialisasi Selesai";
        loaderSubtitle.textContent = "Sistem siap digunakan! Silakan mewarnai kubus.";
        setTimeout(() => {
          loaderOverlay.classList.add('fade-out');
          setTimeout(() => {
            loaderOverlay.classList.add('hidden');
          }, 500);
        }, 800);
      } else {
        throw new Error("Cube library not found or initSolver not available.");
      }
    } catch (e) {
      console.error(e);
      loaderTitle.textContent = "Gagal Menginisialisasi";
      loaderSubtitle.textContent = "Terjadi kesalahan saat memuat modul pemecah kubus: " + e.message;
    }
  }, 500);

  // --- Initialize Event Listeners ---
  btnNetView.addEventListener('click', () => switchView('net'));
  btnSingleView.addEventListener('click', () => switchView('single'));

  colorOptBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      colorOptBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      selectedColor = btn.dataset.color;
      selectedColorLabel.textContent = colorLabels[selectedColor];
      selectedColorLabel.className = `selected-color-label text-${selectedColor}`;
    });
  });

  btnReset.addEventListener('click', resetCube);
  btnScramble.addEventListener('click', scrambleCube);
  btnSolve.addEventListener('click', solveCube);

  // Single face navigation
  btnPrevFace.addEventListener('click', () => navigateFace(-1));
  btnNextFace.addEventListener('click', () => navigateFace(1));
  faceSelBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      changeSingleFace(btn.dataset.face);
    });
  });

  // Step player navigation
  btnStepPrev.addEventListener('click', prevStep);
  btnStepNext.addEventListener('click', nextStep);
  btnStepPlay.addEventListener('click', togglePlay);
  // Guide Modal Dialog binding
  const btnShowGuide = document.getElementById('btn-show-guide');
  const btnCloseGuide = document.getElementById('btn-close-guide');
  const guideModal = document.getElementById('guide-modal');

  if (btnShowGuide && btnCloseGuide && guideModal) {
    btnShowGuide.addEventListener('click', () => {
      guideModal.classList.remove('hidden');
    });

    btnCloseGuide.addEventListener('click', () => {
      guideModal.classList.add('hidden');
    });

    guideModal.addEventListener('click', (e) => {
      if (e.target === guideModal) {
        guideModal.classList.add('hidden');
      }
    });
  }

  // --- Functions ---

  function switchView(view) {
    activeView = view;
    if (view === 'net') {
      btnNetView.classList.add('active');
      btnSingleView.classList.remove('active');
      netViewContainer.classList.remove('hidden');
      singleViewContainer.classList.add('hidden');
      buildNetGrids();
    } else {
      btnNetView.classList.remove('active');
      btnSingleView.classList.add('active');
      netViewContainer.classList.add('hidden');
      singleViewContainer.classList.remove('hidden');
      buildSingleFaceGrid();
    }
  }

  function navigateFace(dir) {
    const currentIndex = faces.indexOf(activeSingleFace);
    let nextIndex = currentIndex + dir;
    if (nextIndex < 0) nextIndex = faces.length - 1;
    if (nextIndex >= faces.length) nextIndex = 0;
    changeSingleFace(faces[nextIndex]);
  }

  function changeSingleFace(face) {
    activeSingleFace = face;
    faceSelBtns.forEach(btn => {
      if (btn.dataset.face === face) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });
    currentFaceTitle.textContent = `Sisi ${faceNames[face]} - Center: ${colorLabels[fixedCenters[face]]}`;
    buildSingleFaceGrid();
  }

  function getFilledCount() {
    let count = 0;
    faces.forEach(f => {
      cubeState[f].forEach(cell => {
        if (cell !== 'none') count++;
      });
    });
    return count;
  }

  function updateProgress() {
    const filled = getFilledCount();
    progressCount.textContent = `${filled} / 54 Kotak`;
    const pct = Math.round((filled / 54) * 100);
    progressBar.style.width = `${pct}%`;
  }

  function resetCube() {
    faces.forEach(f => {
      cubeState[f] = Array(9).fill('none');
      cubeState[f][4] = fixedCenters[f];
    });
    updateProgress();
    if (activeView === 'net') {
      buildNetGrids();
    } else {
      buildSingleFaceGrid();
    }
    // Reset solutions
    validationPanel.classList.add('hidden');
    emptySolutionPanel.classList.remove('hidden');
    solutionPanel.classList.add('hidden');
    stopPlayback();
  }

  function scrambleCube() {
    stopPlayback();
    
    // Generate mathematically valid random state using Kociemba library
    const randomCube = window.Cube.random();
    const kociembaStr = randomCube.asString();
    
    const charToColor = {
      'U': 'yellow',
      'R': 'orange',
      'F': 'green',
      'D': 'white',
      'L': 'red',
      'B': 'blue'
    };
    
    const facesOrder = ['U', 'R', 'F', 'D', 'L', 'B'];
    let strIdx = 0;
    for (let f of facesOrder) {
      for (let i = 0; i < 9; i++) {
        cubeState[f][i] = charToColor[kociembaStr[strIdx]];
        strIdx++;
      }
    }
    
    updateProgress();
    if (activeView === 'net') {
      buildNetGrids();
    } else {
      buildSingleFaceGrid();
    }
    
    validationPanel.classList.add('hidden');
    emptySolutionPanel.classList.remove('hidden');
    solutionPanel.classList.add('hidden');
  }

  function handleCellClick(face, cellIndex, element) {
    if (cellIndex === 4) return; // Cannot change fixed centers
    
    // Toggle color: if already is selectedColor, clear it to none. Otherwise, paint it.
    if (cubeState[face][cellIndex] === selectedColor) {
      cubeState[face][cellIndex] = 'none';
      element.className = 'facelet none';
    } else {
      cubeState[face][cellIndex] = selectedColor;
      element.className = `facelet ${selectedColor}`;
    }
    updateProgress();
  }

  function buildNetGrids() {
    faces.forEach(f => {
      const grid = document.querySelector(`.face-grid[data-face="${f}"]`);
      grid.innerHTML = '';
      for (let i = 0; i < 9; i++) {
        const facelet = document.createElement('div');
        const color = cubeState[f][i];
        facelet.className = `facelet ${color}`;
        if (i === 4) {
          facelet.classList.add('fixed-center');
        } else {
          facelet.addEventListener('click', () => handleCellClick(f, i, facelet));
        }
        grid.appendChild(facelet);
      }
    });
  }

  function buildSingleFaceGrid() {
    singleFaceGrid.innerHTML = '';
    const f = activeSingleFace;
    for (let i = 0; i < 9; i++) {
      const facelet = document.createElement('div');
      const color = cubeState[f][i];
      facelet.className = `facelet ${color}`;
      if (i === 4) {
        facelet.classList.add('fixed-center');
      } else {
        facelet.addEventListener('click', () => {
          handleCellClick(f, i, facelet);
          // Sync back to net view background if loaded next time
        });
      }
      singleFaceGrid.appendChild(facelet);
    }
  }

  // --- Initial Builders ---
  buildNetGrids();

  // --- Validator Logic ---

  function runValidation() {
    const errors = [];
    const filled = getFilledCount();
    
    // 1. Check completeness
    if (filled < 54) {
      errors.push(`Kubus belum lengkap! Masih ada ${54 - filled} kotak kosong.`);
      return { isValid: false, errors };
    }

    // 2. Check color counts
    const counts = { yellow: 0, orange: 0, green: 0, white: 0, red: 0, blue: 0 };
    faces.forEach(f => {
      cubeState[f].forEach(c => {
        if (counts[c] !== undefined) {
          counts[c]++;
        }
      });
    });

    for (let col in counts) {
      if (counts[col] !== 9) {
        errors.push(`Warna ${colorLabels[col]}: ditemukan ${counts[col]} kotak (seharusnya 9).`);
      }
    }

    // 3. Validate Edge configurations
    edges.forEach(edge => {
      const c1 = cubeState[edge.f1][edge.idx1];
      const c2 = cubeState[edge.f2][edge.idx2];

      if (c1 === 'none' || c2 === 'none') return;

      // Opposites rule
      if (opposites[c1] === c2) {
        errors.push(`Edge mustahil: warna ${colorLabels[c1]} bersebelahan dengan warna lawannya ${colorLabels[c2]} (pada sisi ${edge.f1}[${edge.idx1+1}] dan sisi ${edge.f2}[${edge.idx2+1}]).`);
      }
      
      // Duplicates color on the same edge piece
      if (c1 === c2) {
        errors.push(`Edge mustahil: dua warna sama ${colorLabels[c1]} berada pada edge piece yang sama.`);
      }
    });

    // 4. Validate Corner configurations
    corners.forEach(corner => {
      const c1 = cubeState[corner.f1][corner.idx1];
      const c2 = cubeState[corner.f2][corner.idx2];
      const c3 = cubeState[corner.f3][corner.idx3];

      if (c1 === 'none' || c2 === 'none' || c3 === 'none') return;

      // Duplicate color on corner
      if (c1 === c2 || c2 === c3 || c1 === c3) {
        errors.push(`Corner mustahil: ada warna duplikat (${colorLabels[c1]}, ${colorLabels[c2]}, ${colorLabels[c3]}).`);
      }

      // Opposite colors on corner
      const list = [c1, c2, c3];
      for (let i = 0; i < 3; i++) {
        for (let j = i + 1; j < 3; j++) {
          if (opposites[list[i]] === list[j]) {
            errors.push(`Corner mustahil: warna ${colorLabels[list[i]]} dan ${colorLabels[list[j]]} tidak boleh bersebelahan.`);
          }
        }
      }
    });

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // --- Solver Logic ---

  function solveCube() {
    stopPlayback();
    
    // Run validation first
    const valResult = runValidation();
    if (!valResult.isValid) {
      showErrors(valResult.errors);
      return;
    }

    // Hide validation errors
    validationPanel.classList.add('hidden');
    emptySolutionPanel.classList.add('hidden');
    
    // Map colors to Kociemba characters
    // Map: yellow->U, orange->R, green->F, white->D, red->L, blue->B
    const colorToChar = {
      'yellow': 'U',
      'orange': 'R',
      'green': 'F',
      'white': 'D',
      'red': 'L',
      'blue': 'B'
    };

    // Format Kociemba string in order: U(9), R(9), F(9), D(9), L(9), B(9)
    const facesOrder = ['U', 'R', 'F', 'D', 'L', 'B'];
    let kociembaStr = '';
    for (let f of facesOrder) {
      for (let i = 0; i < 9; i++) {
        kociembaStr += colorToChar[cubeState[f][i]];
      }
    }

    console.log("Solving Kociemba string:", kociembaStr);
    
    const startTime = performance.now();
    try {
      const cube = window.Cube.fromString(kociembaStr);
      const rawSolution = cube.solve();
      const endTime = performance.now();
      const solveTime = Math.round(endTime - startTime);
      
      console.log("Raw solution:", rawSolution);
      
      if (!rawSolution) {
        showErrors(["Solusi tidak ditemukan. Pastikan konfigurasi warna dapat dicapai di kubus nyata."]);
        return;
      }
      
      parseAndShowSolution(rawSolution, solveTime, kociembaStr);
      
    } catch (err) {
      console.error(err);
      const endTime = performance.now();
      const solveTime = Math.round(endTime - startTime);
      
      // Map library internal errors to user friendly messages
      let msg = err.message || err;
      if (msg.includes("Error 1") || msg.includes("twisted corner")) {
        msg = "Ada corner piece yang terbalik (Twisted corner). Periksa kembali orientasi sudut.";
      } else if (msg.includes("Error 2") || msg.includes("twisted edge")) {
        msg = "Ada edge piece yang terbalik (Twisted edge). Periksa kembali orientasi tepi.";
      } else if (msg.includes("Error 3") || msg.includes("parity")) {
        msg = "Parity error: konfigurasi kubus tidak mungkin dicapai di dunia nyata. Periksa jika ada stiker tertukar.";
      } else if (msg.includes("Error")) {
        msg = "Konfigurasi kubus tidak valid. Pastikan semua stiker terinput dengan benar.";
      }
      showErrors([msg]);
    }
  }

  function showErrors(errors) {
    errorList.innerHTML = '';
    errors.forEach(err => {
      const li = document.createElement('li');
      li.textContent = err;
      errorList.appendChild(li);
    });
    validationPanel.classList.remove('hidden');
    emptySolutionPanel.classList.add('hidden');
    solutionPanel.classList.add('hidden');
  }

  // --- Solution Viewer UI & Logic ---

  function parseAndShowSolution(rawSolution, solveTime, kociembaStr) {
    validationPanel.classList.add('hidden');
    solutionPanel.classList.remove('hidden');
    
    solveTimeBadge.textContent = `${solveTime} ms`;
    algorithmNotation.textContent = rawSolution;

    // Parse solution string into steps array
    // Example rawSolution: "R2 L' U D2 R L' F2"
    const moves = rawSolution.trim().split(/\s+/).filter(x => x.length > 0);
    solutionSteps = [];

    // Map each move notation to descriptions
    moves.forEach((notation, index) => {
      const step = describeMove(notation, index + 1, kociembaStr);
      solutionSteps.push(step);
    });

    if (solutionSteps.length === 0) {
      // Cube is already solved
      solutionSteps.push({
        stepNumber: 1,
        notation: 'Solved',
        face: 'U',
        direction: 'Solved',
        description: 'Kubus sudah dalam keadaan selesai (Solved)!',
        faceState: cubeState['U'] // dummy
      });
    }

    // Build the steps list on the right bottom scroll container
    buildStepsScrollList();

    // Load first step in visualizer player
    currentStepIndex = 0;
    loadPlayerStep(currentStepIndex);
  }

  function describeMove(notation, stepNumber, initialKociembaStr) {
    const base = notation[0]; // U, D, R, L, F, B
    
    const faceLabels = {
      'U': 'Atas (Up) - Kuning',
      'D': 'Bawah (Down) - Putih',
      'R': 'Kanan (Right) - Oranye',
      'L': 'Kiri (Left) - Merah',
      'F': 'Depan (Front) - Hijau',
      'B': 'Belakang (Back) - Biru'
    };

    const perspektif = {
      'U': 'Lihat kubus dari ATAS.',
      'D': 'Lihat kubus dari BAWAH.',
      'F': 'Lihat sisi DEPAN.',
      'B': 'Lihat sisi BELAKANG (putar kubus 180°).',
      'R': 'Lihat sisi KANAN.',
      'L': 'Lihat sisi KIRI.',
    };

    let direction = '';
    let description = '';

    if (notation.length === 1) {
      direction = '90° searah jarum jam ↻';
      description = `${perspektif[base]} Putar sisi ${faceLabels[base]} 90° searah jarum jam ↻.`;
    } else if (notation.endsWith("'")) {
      direction = "90° berlawanan jarum jam ↺";
      description = `${perspektif[base]} Putar sisi ${faceLabels[base]} 90° berlawanan jarum jam ↺.`;
    } else if (notation.endsWith('2')) {
      direction = '180° (setengah putaran)';
      description = `${perspektif[base]} Putar sisi ${faceLabels[base]} 180° (setengah putaran).`;
    }

    // Retrieve face state dynamically for the visualizer
    // For simplicity, we grab the current state of that face from cubeState
    // However, as moves accumulate, the faces rotate.
    // For visual clarity, we display the face's configuration.
    // We can simulate the moves on a temporary Cube model to find exact facelet colors!
    // Let's do this: apply previous moves to get the exact colors of this face!
    const tempCube = window.Cube.fromString(initialKociembaStr);
    
    // Apply moves up to this step (exclusive)
    const prevMoves = solutionSteps.map(s => s.notation);
    if (prevMoves.length > 0) {
      tempCube.move(prevMoves.join(' '));
    }
    
    // Now get the state of this face
    const tempKociemba = tempCube.asString();
    const faceColors = getFaceColorsFromKociemba(tempKociemba, base);

    return {
      stepNumber,
      notation,
      face: base,
      direction,
      description,
      faceColors
    };
  }

  function getFaceColorsFromKociemba(kociembaStr, face) {
    const faceIndices = {
      'U': [0, 9],
      'R': [9, 18],
      'F': [18, 27],
      'D': [27, 36],
      'L': [36, 45],
      'B': [45, 54]
    };

    const range = faceIndices[face];
    const substring = kociembaStr.substring(range[0], range[1]);
    
    // Convert URFDLB chars back to colors
    const charToColor = {
      'U': 'yellow',
      'R': 'orange',
      'F': 'green',
      'D': 'white',
      'L': 'red',
      'B': 'blue'
    };

    return substring.split('').map(c => charToColor[c]);
  }

  function buildStepsScrollList() {
    stepsScrollList.innerHTML = '';
    solutionSteps.forEach((step, index) => {
      const item = document.createElement('div');
      item.className = 'step-list-item';
      if (index === currentStepIndex) item.classList.add('active');
      
      item.innerHTML = `
        <div class="step-item-num">${step.stepNumber}</div>
        <div class="step-item-notation">${step.notation}</div>
        <div class="step-item-desc">${step.description}</div>
      `;

      item.addEventListener('click', () => {
        stopPlayback();
        currentStepIndex = index;
        loadPlayerStep(index);
      });

      stepsScrollList.appendChild(item);
    });
  }

  function loadPlayerStep(index) {
    if (index < 0 || index >= solutionSteps.length) return;
    
    currentStepIndex = index;
    const step = solutionSteps[index];

    // Update steps list active item
    const items = stepsScrollList.querySelectorAll('.step-list-item');
    items.forEach((item, idx) => {
      if (idx === index) {
        item.classList.add('active');
        item.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      } else {
        item.classList.remove('active');
      }
    });

    // Update text labels
    stepCounter.textContent = `LANGKAH ${step.stepNumber} DARI ${solutionSteps.length}`;
    stepNotationBadge.textContent = step.notation;
    
    const faceLabelNames = {
      'U': 'Sisi Atas (Kuning)',
      'D': 'Sisi Bawah (Putih)',
      'R': 'Sisi Kanan (Oranye)',
      'L': 'Sisi Kiri (Merah)',
      'F': 'Sisi Depan (Hijau)',
      'B': 'Sisi Belakang (Biru)'
    };
    stepFaceTitle.textContent = faceLabelNames[step.face] || step.face;
    stepDescText.textContent = step.description;

    // Draw the mini face in player
    visualizerFace.innerHTML = '';
    const colors = step.faceColors || Array(9).fill('none');
    colors.forEach((col, cIdx) => {
      const cell = document.createElement('div');
      cell.className = `facelet ${col}`;
      if (cIdx === 4) cell.classList.add('fixed-center');
      visualizerFace.appendChild(cell);
    });

    // Draw SVG Rotation Arrow overlay
    drawRotationArrow(step.notation);

    // Disable/enable navigation buttons
    btnStepPrev.disabled = (index === 0);
    btnStepNext.disabled = (index === solutionSteps.length - 1);
  }

  function drawRotationArrow(notation) {
    const isClockwise = (notation.length === 1);
    const isCounter = notation.endsWith("'");
    const isDouble = notation.endsWith('2');

    // Arrow SVG paths for a 100x100 box
    if (isClockwise) {
      // Circular arc going Clockwise (from 10 o'clock to 6 o'clock clockwise)
      arrowPath.setAttribute('d', 'M 35 25 A 32 32 0 1 1 78 62');
    } else if (isCounter) {
      // Circular arc going Counter-clockwise (from 2 o'clock to 6 o'clock counter-clockwise)
      arrowPath.setAttribute('d', 'M 65 25 A 32 32 0 1 0 22 62');
    } else if (isDouble) {
      // Large 180 degrees arc (from 11 o'clock clockwise to 7 o'clock)
      arrowPath.setAttribute('d', 'M 40 20 A 32 32 0 1 1 30 75');
    } else {
      arrowPath.setAttribute('d', '');
    }
  }

  // --- Step Playback Functions ---

  function prevStep() {
    if (currentStepIndex > 0) {
      currentStepIndex--;
      loadPlayerStep(currentStepIndex);
    }
  }

  function nextStep() {
    if (currentStepIndex < solutionSteps.length - 1) {
      currentStepIndex++;
      loadPlayerStep(currentStepIndex);
    } else {
      stopPlayback();
    }
  }

  function togglePlay() {
    if (isPlaying) {
      stopPlayback();
    } else {
      startPlayback();
    }
  }

  function startPlayback() {
    isPlaying = true;
    playIcon.textContent = 'pause';
    btnStepPlay.classList.add('active');
    
    // Auto-advance step every 2.5 seconds
    playInterval = setInterval(() => {
      nextStep();
    }, 2500);
  }

  function stopPlayback() {
    isPlaying = false;
    playIcon.textContent = 'play_arrow';
    btnStepPlay.classList.remove('active');
    
    if (playInterval) {
      clearInterval(playInterval);
      playInterval = null;
    }
  }
});
