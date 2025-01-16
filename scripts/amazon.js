import { products } from '../data/products.js';

// Initialize cart
let cart = [];

// Clear cart and localStorage on page refresh
window.addEventListener('load', () => {
  localStorage.removeItem('cart');
  cart = [];
  document.querySelector('.js-cart-button').textContent = 0; // Reset cart display
});

let productsHtml = '';

// Render products into the HTML
products.forEach((product) => {
  productsHtml += `
    <div class="product-container">
      <div class="product-image-container">
        <img class="product-image" src="${product.image}">
      </div>

      <div class="product-name limit-text-to-2-lines">
        ${product.name}
      </div>

      <div class="product-rating-container">
        <img class="product-rating-stars" src="images/ratings/rating-${product.rating.stars * 10}.png">
        <div class="product-rating-count link-primary">
          ${product.rating.count}
        </div>
      </div>

      <div class="product-price">
        ${(product.priceCents / 100).toFixed(2)}
      </div>

      <div class="product-quantity-container">
        <select class="js-quantity-select">
          <option selected value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
          <option value="5">5</option>
          <option value="6">6</option>
          <option value="7">7</option>
          <option value="8">8</option>
          <option value="9">9</option>
          <option value="10">10</option>
        </select>
      </div>

      <div class="product-spacer"></div>

      <div class="added-to-cart" style="display: none;">
        <img src="images/icons/checkmark.png">
        Added
      </div>

      <button class="add-to-cart-button button-primary js-add-to-cart" data-product-id="${product.id}">
        Add to Cart
      </button>
    </div>
  `;
});

document.querySelector('.js-products-container').innerHTML = productsHtml;

// Add to Cart button functionality
document.querySelectorAll('.js-add-to-cart').forEach((button) => {
  button.addEventListener('click', () => {
    const productId = button.dataset.productId;

    // Check if the product is already in the cart
    let matching = cart.find((item) => item.productId === productId);

    if (matching) {
      matching.quantity += 1; // Increase quantity if the product exists in the cart
    } else {
      cart.push({
        productId: productId,
        quantity: 1,
      });
    }

    // Update the cart quantity in the header
    const cartQuantity = cart.reduce((total, item) => total + item.quantity, 0);
    document.querySelector('.js-cart-button').textContent = cartQuantity;

    // Show "Added to Cart" message
    const addedMessage = button.previousElementSibling;
    addedMessage.style.display = 'block';

    // Hide the message after 2 seconds
    setTimeout(() => {
      addedMessage.style.display = 'none';
    }, 2000);
  });
});
