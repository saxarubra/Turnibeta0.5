import React from "react";

const TestApiButton: React.FC = () => {
  const handleSendEmail = async () => {
    const apiUrl = import.meta.env.VITE_API_BASE_URL;

    try {
      const response = await fetch(`${apiUrl}/send-swap-email`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          to: "saxarubra915@gmail.com",
          subject: "Test",
          html: "<b>Ciao!</b>"
        })
      });

      const data = await response.json();
      alert(JSON.stringify(data, null, 2));
    } catch (error) {
      if (error instanceof Error) {
        alert("Errore: " + error.message);
      } else {
        alert("Errore sconosciuto");
      }
    }
  };

  return (
    <button onClick={handleSendEmail}>
      Test invio email API
    </button>
  );
};

export default TestApiButton;