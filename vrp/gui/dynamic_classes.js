const dynamic_classes = {};

//define a dynamic class (every elements with this class will trigger the callback passing themselves when added)
function defineDynamicClass(classname, callback)
{
  dynamic_classes[classname] = callback;
}

const handle_inserted_element = function (el) {
  //callbacks
  if (el.classList) {
    for (let i = 0; i < el.classList.length; i++) {
      const cb = dynamic_classes[el.classList[i]];
      if (cb)
        cb(el);
    }
  }

  //children
  let children = el.childNodes;
  if (children) {
    for (let i = 0; i < children.length; i++)
      handle_inserted_element(children[i]);
  }
};

const observer = new MutationObserver(function (mutations) {
  mutations.forEach(function (mutation) {
    for (let i = 0; i < mutation.addedNodes.length; i++) {
      let el = mutation.addedNodes[i];
      handle_inserted_element(el);
    }
  });
});

window.addEventListener("load",function(){
  observer.observe(document.body, { childList: true, subtree: true });
});
