const windowsForms = document.querySelectorAll(".windows-form[data-signup-type]");
const configuredEndpoints = {
  beta:
    document.documentElement.dataset.betaSignupEndpoint ||
    window.SPOOFTRAP_WINDOWS_BETA_SIGNUP_ENDPOINT ||
    "",
  notify:
    document.documentElement.dataset.notifySignupEndpoint ||
    window.SPOOFTRAP_WINDOWS_NOTIFY_SIGNUP_ENDPOINT ||
    "",
};

function setFormStatus(form, message, state) {
  const status = form.querySelector(".windows-form-status");
  if (!status) {
    return;
  }

  status.textContent = message;
  status.dataset.state = state;
}

function toggleFormSuccess(form, visible) {
  const success = form.querySelector(".windows-form-success");
  if (!success) {
    return;
  }

  success.setAttribute("aria-hidden", visible ? "false" : "true");
  form.classList.toggle("is-success", visible);
}

function getFieldValue(form, selector) {
  const field = form.querySelector(selector);
  return field ? field.value.trim() : "";
}

function buildPayload(form) {
  const type = form.dataset.signupType;

  if (type === "beta") {
    return {
      type,
      name: getFieldValue(form, 'input[name="beta-name"]'),
      email: getFieldValue(form, 'input[name="beta-email"]'),
      discord: getFieldValue(form, 'input[name="beta-discord"]'),
      notes: getFieldValue(form, 'textarea[name="beta-notes"]'),
    };
  }

  return {
    type,
    name: getFieldValue(form, 'input[name="notify-name"]'),
    email: getFieldValue(form, 'input[name="notify-email"]'),
    discord: getFieldValue(form, 'input[name="notify-discord"]'),
    notes: getFieldValue(form, 'textarea[name="notify-notes"]'),
  };
}

function getSignupEndpoint(form) {
  const type = form.dataset.signupType;
  return configuredEndpoints[type] || "";
}

function buildFormspreePayload(payload) {
  return {
    signup_type: payload.type,
    name: payload.name,
    email: payload.email,
    discord_username: payload.discord,
    notes: payload.notes,
    source_page: "windows-roadmap",
  };
}

async function submitWindowsForm(event) {
  event.preventDefault();

  const form = event.currentTarget;
  const submitButton = form.querySelector('button[type="submit"]');
  const payload = buildPayload(form);
  const signupEndpoint = getSignupEndpoint(form);

  if (!payload.email) {
    toggleFormSuccess(form, false);
    setFormStatus(form, "Email is required.", "error");
    return;
  }

  if (!signupEndpoint) {
    toggleFormSuccess(form, false);
    setFormStatus(form, "Signup endpoint is not configured yet.", "error");
    return;
  }

  if (submitButton) {
    submitButton.disabled = true;
  }

  setFormStatus(form, "Sending...", "pending");
  toggleFormSuccess(form, false);

  try {
    const response = await fetch(signupEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(buildFormspreePayload(payload)),
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(result.error || "Could not submit the form.");
    }

    form.reset();
    setFormStatus(form, "", "success");
    toggleFormSuccess(form, true);
  } catch (error) {
    toggleFormSuccess(form, false);
    setFormStatus(form, error.message || "Could not submit the form.", "error");
  } finally {
    if (submitButton) {
      submitButton.disabled = false;
    }
  }
}

windowsForms.forEach((form) => {
  form.addEventListener("submit", submitWindowsForm);
});
