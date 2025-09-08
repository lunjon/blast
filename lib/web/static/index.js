// Application state.
let running = false;
let pollId = undefined;

function setText(id, text) {
  document.getElementById(id).textContent = text;
}

// Requires that `running` is updated accordingly prior calling this.
function toggleButtonMode() {
  // TODO: set button styling when changing mode.
  const value = running ? "STOP" : "START"
  document.getElementById("button").innerHTML = value;
}

const setStatus = (status) => setText("status", status);

// Used to set the error box.
// Pass a falsy value to hide the box.
function setError(message) {
  const div = document.getElementById("error");
  if (message) {
    div.style.visibility = 'visible';
    div.innerHTML = `
    <h1>Error</h1>
    <p>${message}</p>
    `;
  } else {
    // Hide and reset content.
    div.style.visibility = 'hidden';
    div.innerHTML = "";
  }
}

async function send(path) {
  const p = path.replace(/\//, "");
  const response = await fetch(`http://localhost:4000/${p}`);
  if (!response.ok) {
    console.log(`Unexpected status from request: GET ${path} - status ${response.status}`);

    // Try parsing an error from the response.
    const { error } = await response.json();
    setError(error);

    throw new Error("Request was not OK");
  }

  return response;
}

async function pollData() {
  try {
    const response = await send("/data");

    // Replace data's inner HTML with the response.
    const html = await response.text();
    document.getElementById("data").innerHTML = html;
  } catch (error) {
    setError(error.message)
  }
}

async function startBlast() {
  const response = await send("/start");
  if (response.status === 200) {
    setText("data", "Starting...");

    pollId = setInterval(pollData, 2000);
    running = true;
  }
}

async function stopBlast() {
  const response = await send("/stop");
  if (response.status === 200) {
    clearInterval(pollId);
    running = false;
  }
}

async function toggleBlast() {
  setError(null);

  if (running) {
    await stopBlast();
  } else {
    await startBlast()
  }

  toggleButtonMode()
}

// Register callback to load. The user may refresh the page,
// meaning that we should check current state of the application
// so that the state is set correctly.
document.addEventListener("DOMContentLoaded", async () => {
  const res = await send("/status");
  const { running } = await res.json();
  if (running) {
    await startBlast();
    toggleButtonMode()
  }
});
