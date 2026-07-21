// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
//= require moment
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require select2-full
//= require activestorage
//= require bootstrap-sprockets
//= require bootstrap-datepicker/core
//= require_tree .


$.fn.datepicker.dates['zh-cn'] = {
    days: ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"],
    daysShort: ["日", "一", "二", "三", "四", "五", "六"],
    daysMin: ["日", "一", "二", "三", "四", "五", "六"],
    months: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    monthsShort: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"],
    today: "今天",
    clear: "清除",
    format: "yyyy-mm-dd",
    titleFormat: "yyyy年 MM",
    weekStart: 0
};

// select2 的下拉面板 CSS 写死 z-index: 1051；Bootstrap 5 的 .modal 是
// z-index: 1055（BS3/BS4 时代 modal <= 1050，这个问题当时不存在）。下拉
// 面板默认挂载在 <body> 下，落在 modal 的 DOM 子树之外，于是整个 modal
// 的层叠上下文盖在下拉面板上面，导致 modal 内的 select2 选项点不中
// （点击被 modal 子树内的其它元素拦截）。
//
// 官方修法：dropdownParent，让下拉面板挂载到 modal 自身内部，从而进入
// modal 的层叠上下文，而不是去覆盖 z-index（Bootstrap 版本一变数字又要
// 调，是打补丁不是根治）。
//
// 逐元素判断是否处于 .modal 内：不在 modal 内的 select2（不能假设永远
// 在弹窗里）不设置 dropdownParent，行为与之前一致，默认挂载到 <body>。
//
// 全站唯一的 select2 初始化入口——不要在各表单里各写一份
// `$('.select2').select2()`，那样这次修复也无法覆盖到它们。
function initSelect2($elements, options) {
    $elements.each(function () {
        var $el = $(this);
        var $modal = $el.closest('.modal');
        var opts = $.extend({}, options, $modal.length ? { dropdownParent: $modal } : {});
        $el.select2(opts);
    });
}

var initPage = function () {
    // Clean up modal data on close
    $(".modal").on("hidden.bs.modal", function() {
        $(this).removeData("bs.modal");
        // Bootstrap 5: also clean up modal instance
        var modalInstance = bootstrap.Modal.getInstance(this);
        if (modalInstance) {
            modalInstance.dispose();
        }
    });

    // Initialize datepickers
    $('.datepicker').datepicker({
        autoclose: true,
        language: 'zh-cn'
    });

    // Initialize select2
    initSelect2($('.select2'), { width: '100%' });

    // Sidebar toggle
    $('.navbar-toggle-btn').on('click', function() {
        $('body').toggleClass('sidebar-collapsed');
    });

    // Sidebar submenu toggle
    $('.sidebar-menu > li > a[data-bs-toggle="collapse"]').on('click', function(e) {
        e.preventDefault();
    });
};


// File preview in modal
function show_file(e){
    var filename = $(e).attr('data-file-name');
    var url = $(e).attr('data-url');
    var ext = filename.split('.').pop().toLowerCase();
    $('#file-modal-label').text($(e).attr('data-file-name'));
    if(['docx', 'doc', 'ppt', 'pptx', 'xls', 'xlsx'].indexOf(ext) >= 0){
        $('#file-modal-body').html("<iframe src='https://view.officeapps.live.com/op/embed.aspx?src=" + url +"' width='100%' height='100%' frameborder='0'></iframe>");
    }else if(['pdf'].indexOf(ext) >= 0){
        $('#file-modal-body').html("<iframe src='/pdfjs-2.0.943-dist/web/viewer.html?file=" + url + "' width='100%' height='100%' frameborder='0' scrolling='no'></iframe>");
    }else if(['png', 'jpg', 'jepg', 'gif', 'bmp'].indexOf(ext) >= 0){
        $('#file-modal-body').html("<div style='text-align:center;'><image style='max-width:90%' src='"+ url + "'></image></div>");
    }else if(['dwg'].indexOf(ext) >= 0) {
        $('#file-modal-body').html("<iframe src='//sharecad.org/cadframe/load?url=" + url + "' width='100%' height='100%' frameborder='0' scrolling='no'></iframe>");
    }else{
        ext = url.split('.').pop().toLowerCase();
        if(['stl'].indexOf(ext) >= 0) {
            $('#file-modal-body').html('<iframe id="viewer" align="middle" width="1024" height="620" src="http://mo3d.mohou.com/mo3d/moview.htm?width=1024&amp;height=620&amp;id=102097&amp;file=' + url + '" frameborder="0" scrolling="no" style=""></iframe>');
            $('#share').hide();
        }else{
            alert('该文件格式暂时不支持在线预览，点击确定后直接下载文件。');
            location.href = url;
            return;
        }
    }
    var fileModal = new bootstrap.Modal(document.getElementById('file-modal'));
    fileModal.show();
}

$(document).ready(initPage);


function showSpinner() {
    $("#spinner").addClass("spinner");
}

function hideSpinner() {
    $("#spinner").removeClass("spinner");
}

function show_flash(type, message){
    $(".page_tips").fadeIn(function(){
        setTimeout(function(){
            $(".page_tips").fadeOut();
            $(".page_tips").html('');
        }, 3000);
    });
    $(".page_tips").append(
        '<div class="' + type +'"> <div class="inner">'+ message + '<i class="fa fa-close close-tips"></i> </div> </div>');
}

// Bootstrap 3 会自动把触发链接的 href 内容抓进 .modal-content（remote modal），
// Bootstrap 4 移除了该特性。本项目从 BS3 迁到 BS5 时未补替代实现，导致全站
// 所有 data-bs-toggle="modal" 的入口（添加/编辑/上传/历史版本）点开都是空弹窗。
// 这里补回等价行为。
$(function () {
  var $modal = $('#global-modal');
  if (!$modal.length) return;

  $(document).on('click', '[data-bs-toggle="modal"][data-bs-target="#global-modal"]', function () {
    var url = $(this).attr('href');
    if (!url || url === '#') return;

    // 弹窗内容是独立的一次请求，不会继承当前页面 URL 上的 ?locale=。
    // 不带上它的话，中文界面点开的表单会渲染成默认语言（英文）。
    var locale = document.documentElement.lang;
    if (locale) {
      url += (url.indexOf('?') === -1 ? '?' : '&') + 'locale=' + encodeURIComponent(locale);
    }

    $modal.find('.modal-content').html('');
    showSpinner();

    $.get(url)
      .done(function (html) {
        $modal.find('.modal-content').html(html);
      })
      .fail(function (xhr) {
        // layouts/_tips.html.erb stamps the server-translated string onto
        // .page_tips as data-unauthorized — this plain .js asset has no ERB
        // processing of its own, so it cannot call t() directly.
        show_flash('failed', xhr.status === 403 ? $('.page_tips').data('unauthorized') : $('.page_tips').data('load-failed'));
        $modal.modal('hide');
      })
      .always(hideSpinner);
  });

  // 关闭后清空，避免下次打开时闪现上一次的内容
  $modal.on('hidden.bs.modal', function () {
    $modal.find('.modal-content').html('');
  });
});

// Server-rendered tree table (P5 Task 6, replaces bootstrap-treetable.min.js).
// app/views/shared/_list.html.erb renders every row up front, each tagged
// with data-depth="N"; rows below depth 0 start hidden via the "d-none"
// class. Clicking a row's .tree-toggle button reveals/hides its whole
// subtree at once: every immediately-following row whose depth is greater
// than the clicked row's, stopping at the first row whose depth is <= it.
document.addEventListener('click', function (event) {
  var toggle = event.target.closest('.tree-toggle');
  if (!toggle) return;

  var row = toggle.closest('tr');
  var depth = parseInt(row.getAttribute('data-depth'), 10);
  var expanding = toggle.classList.contains('collapsed');
  var sibling = row.nextElementSibling;

  while (sibling && parseInt(sibling.getAttribute('data-depth'), 10) > depth) {
    sibling.classList.toggle('d-none', !expanding);
    sibling = sibling.nextElementSibling;
  }

  toggle.classList.toggle('collapsed', !expanding);
});
