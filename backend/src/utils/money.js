// All money is stored and calculated as integer paisa (1 rupee = 100 paisa).

function rupeesToPaisa(rupees) {
  const p = Math.round(Number(rupees) * 100);
  if (!Number.isFinite(p)) throw new Error('Invalid amount');
  return p;
}

const paisaToRupees = (paisa) => paisa / 100;

// Nepali/Indian digit grouping: 1,00,000.00
function formatNpr(paisa) {
  const negative = paisa < 0;
  const abs = Math.abs(paisa);
  const rupees = Math.floor(abs / 100).toString();
  const decimals = String(abs % 100).padStart(2, '0');
  const last3 = rupees.slice(-3);
  const rest = rupees.slice(0, -3).replace(/\B(?=(\d{2})+(?!\d))/g, ',');
  const grouped = rest ? `${rest},${last3}` : last3;
  return `${negative ? '-' : ''}Rs. ${grouped}.${decimals}`;
}

const ONES = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven',
  'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
const TENS = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

function twoDigits(n) {
  if (n < 20) return ONES[n];
  return `${TENS[Math.floor(n / 10)]}${n % 10 ? ` ${ONES[n % 10]}` : ''}`;
}

function threeDigits(n) {
  const h = Math.floor(n / 100);
  const r = n % 100;
  return [h ? `${ONES[h]} Hundred` : '', r ? twoDigits(r) : ''].filter(Boolean).join(' ');
}

// Words using the South Asian system: crore, lakh, thousand.
function integerToWords(n) {
  if (n === 0) return 'Zero';
  const parts = [];
  const crore = Math.floor(n / 10000000);
  const lakh = Math.floor((n % 10000000) / 100000);
  const thousand = Math.floor((n % 100000) / 1000);
  const rest = n % 1000;
  if (crore) parts.push(`${integerToWords(crore)} Crore`);
  if (lakh) parts.push(`${twoDigits(lakh)} Lakh`);
  if (thousand) parts.push(`${twoDigits(thousand)} Thousand`);
  if (rest) parts.push(threeDigits(rest));
  return parts.join(' ');
}

function amountInWords(paisa) {
  const rupees = Math.floor(paisa / 100);
  const ps = paisa % 100;
  let words = `${integerToWords(rupees)} Nepalese Rupees`;
  if (ps) words += ` and ${twoDigits(ps)} Paisa`;
  return `${words} Only`;
}

module.exports = { rupeesToPaisa, paisaToRupees, formatNpr, amountInWords };
