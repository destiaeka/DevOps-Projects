const board = document.getElementById("board");
const statusText = document.getElementById("status");

let currentPlayer = "X";
let gameState = Array(9).fill("");
let gameActive = true;

const winConditions = [
  [0,1,2],[3,4,5],[6,7,8],
  [0,3,6],[1,4,7],[2,5,8],
  [0,4,8],[2,4,6]
];

function createBoard() {
  board.innerHTML = "";
  gameState.forEach((cell, index) => {
    const div = document.createElement("div");
    div.classList.add("cell");
    div.dataset.index = index;
    div.addEventListener("click", handleMove);
    div.textContent = cell;
    board.appendChild(div);
  });
}

function handleMove(e) {
  const index = e.target.dataset.index;

  if (gameState[index] !== "" || !gameActive) return;

  gameState[index] = currentPlayer;
  e.target.textContent = currentPlayer;

  if (checkWinner()) {
    statusText.textContent = `Player ${currentPlayer} Wins!`;
    gameActive = false;
    return;
  }

  if (!gameState.includes("")) {
    statusText.textContent = "Draw!";
    gameActive = false;
    return;
  }

  currentPlayer = currentPlayer === "X" ? "O" : "X";
  statusText.textContent = `Player ${currentPlayer} Turn`;
}

function checkWinner() {
  return winConditions.some(condition => {
    const [a, b, c] = condition;
    return (
      gameState[a] &&
      gameState[a] === gameState[b] &&
      gameState[a] === gameState[c]
    );
  });
}

function restartGame() {
  currentPlayer = "X";
  gameState = Array(9).fill("");
  gameActive = true;
  statusText.textContent = "Player X Turn";
  createBoard();
}

createBoard();
