import { LightningElement, api } from 'lwc';

export default class Pagination extends LightningElement {
    @api currentPage = 1;
    @api totalPages = 1;

    get disablePrevious() {
        return this.currentPage <= 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    get pageNumbers() {
        const pages = [];
        const totalPages = this.totalPages;
        const currentPage = this.currentPage;
        
        if (totalPages <= 1) {
            return [];
        }
        
        if (totalPages <= 7) {
            for (let i = 1; i <= totalPages; i++) {
                pages.push(i);
            }
        } else {
            if (currentPage <= 4) {
                for (let i = 1; i <= 5; i++) {
                    pages.push(i);
                }
                if (totalPages > 6) {
                    pages.push('...');
                    pages.push(totalPages);
                }
            } else if (currentPage >= totalPages - 3) {
                pages.push(1);
                if (totalPages > 6) {
                    pages.push('...');
                }
                for (let i = totalPages - 4; i <= totalPages; i++) {
                    pages.push(i);
                }
            } else {
                pages.push(1);
                pages.push('...');
                for (let i = currentPage - 1; i <= currentPage + 1; i++) {
                    pages.push(i);
                }
                pages.push('...');
                pages.push(totalPages);
            }
        }
        
        return pages.map(page => ({
            number: page,
            isEllipsis: page === '...',
            isCurrent: page === currentPage ? 'brand' : 'neutral'
        }));
    }

    handleFirstPage() {
        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: { page: 1, action: 'first' }
        }));
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: { page: this.currentPage - 1, action: 'previous' }
            }));
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: { page: this.currentPage + 1, action: 'next' }
            }));
        }
    }

    handleLastPage() {
        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: { page: this.totalPages, action: 'last' }
        }));
    }

    handlePageClick(event) {
        const pageNumber = parseInt(event.target.dataset.page);
        if (pageNumber && pageNumber !== this.currentPage) {
            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: { page: pageNumber, action: 'click' }
            }));
        }
    }
}