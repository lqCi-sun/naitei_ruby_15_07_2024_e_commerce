//= require toastr
//= require social-share-button
import '@hotwired/turbo-rails'
import 'controllers'
import 'custom/menu'
import './config/jquery'
import './products/show_products.js'
import { Turbo } from '@hotwired/turbo-rails'
import './orders/_receive_info.js'
import './controllers/toastr.min'
import './carts/cart_cookie.js'
import './admin/image_input.js'

document.addEventListener('DOMContentLoaded', function() {
  const showLoginPopup = document.getElementById('show-login-popup');
  const loginPopup = document.getElementById('login-popup');
  const closeModal = document.getElementById('close-modal');

  if (showLoginPopup) {
    showLoginPopup.addEventListener('click', function() {
      loginPopup.style.display = 'flex';
    });

    closeModal.addEventListener('click', function() {
      loginPopup.style.display = 'none';
    });

    window.addEventListener('click', function(event) {
      if (event.target === loginPopup) {
        loginPopup.style.display = 'none';
      }
    });
  }
});
