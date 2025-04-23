const axios = require('axios');

async function autenticar(req, res) {
  const { username, password } = req.body;

  try {
    const response = await axios.post('https://sua-api.com/auth', {
      username,
      password
    });

    res.json(response.data);
  } catch (error) {
    console.error(error); // Ajuda a debugar
    res.status(500).json({ error: 'Erro na autenticação' });
  }
}

module.exports = {
  autenticar
};
